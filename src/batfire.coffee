class BatFire
class BatFire.Reference
  constructor: ({@path, @parent}) ->
    if @parent
      @ref = @parent.child(@path)
    else
      @ref = new Firebase(@path)

  child: (path) ->
    @ref.child(path)

BatFire.AppMixin =
  initialize: ->
    @syncsWithFirebase = (@firebaseAppName) ->
      @firebaseURL = "https://#{@firebaseAppName}.firebaseio.com/"
      @firebase = new BatFire.Reference(path: @firebaseURL)

    @syncs = (keypathString, {as}={}) ->
      @_syncKeypaths ?= []
      @_syncKeypaths.push(keypathString)
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @firebase.child("BatFire/#{firebasePath}")
      syncConstructor = as
      @observe keypathString, (newValue, oldValue) =>
        return if newValue is oldValue or Batman.typeOf(newValue) is 'Undefined'
        newValue = newValue.toJSON() if newValue?.toJSON
        childRef.set(newValue)
      childRef.on 'value', (snapshot) =>
        value = snapshot.val()
        if syncConstructor?
          value = new syncConstructor(value)
        @set(keypathString, value)

    @_updateFirebaseChild = (keypathString, newValue) ->
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @firebase.child("BatFire/#{firebasePath}")
      newValue = newValue.toJSON() if newValue?.toJSON
      childRef.set(newValue)

    appSet = @set
    @set = ->
      keypathString = arguments[0]
      value = arguments[1]
      firstKeypathPart = keypathString.split(".")[0]
      if firstKeypathPart in(@_syncKeypaths || [])
        @_updateFirebaseChild(keypathString, value)
      appSet.apply(@, arguments)

Batman.App.classMixin(BatFire.AppMixin)

class BatFire.Storage extends Batman.StorageAdapter
  @ModelMixin =
    initialize: ->
      @encode(@model.primaryKey)

      _BatFireClearLoaded = @clear
      @clear = =>
        result = _BatFireClearLoaded.apply(@model)
        @storageAdapter()._listeningToList = false
        delete @_firebaseListRef
        result

      _BatFireLoadRecords = @load
      @load = (options, callback) =>
        Batman.developer.warn("Firebase doesn't return all records at once!")
        _BatFireLoadRecords.apply(@model, options, callback)

  constructor: ->
    super
    @firebaseClass = Batman.helpers.pluralize(@model.resourceName)
    @model.classMixin(@ModelMixin)

  _listenToList: ->
    if !@_listeningToList
      @model._firebaseListRef ?= Batman.currentApp.firebase.child(@firebaseClass)
      @model._firebaseListRef.on 'child_added', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
      @model._firebaseListRef.on 'child_removed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
        @model.get('loaded').remove(record)
      @model._firebaseListRef.on 'child_changed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
    @_listeningToList = true

  @::before 'create', 'update', 'read', 'destroy', 'readAll', 'destroyAll', @skipIfError (env, next) ->
    @firebaseListRef ?= Batman.currentApp.firebase.child(@firebaseClass)
    if env.subject.get('id')
      env.firebaseRef = @firebaseListRef.child(env.subject.get('id'))
    else if env.action is 'readAll' or env.action is 'destroyAll'
      env.firebaseRef = @firebaseListRef
    else
      env.firebaseRef = @firebaseListRef.push()
    next()

  @::after 'create', 'update', 'read', 'destroy', @skipIfError (env, next) ->
    env.result = env.subject
    next()

  @::after 'readAll', @skipIfError (env, next) ->
    env.result = []
    next()

  create: @skipIfError (env, next) ->
    firebaseId = env.firebaseRef.name()
    env.subject._withoutDirtyTracking -> @set(env.subject.constructor.primaryKey, firebaseId)
    env.firebaseRef.set env.subject.toJSON(), (err) ->
      if err
        env.error = err
        console.log err
      next()

  read: @skipIfError (env, next) ->
    env.firebaseRef.once 'value', (snapshot) =>
      data = snapshot.val()
      if !data?
        env.error = new @constructor.NotFoundError
      else
        env.subject._withoutDirtyTracking -> @fromJSON(data)
      next()

  update: @skipIfError (env, next) ->
    env.firebaseRef.set env.subject.toJSON(), (err) ->
      if err
        env.error = err
        console.log err
      next()

  destroy: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()

  readAll: @skipIfError (env, next) ->
    @_listenToList()
    next()

  destroyAll:  @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()


