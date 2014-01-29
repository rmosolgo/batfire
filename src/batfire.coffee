class BatFire
class BatFire.Reference
  constructor: ({@path, @parent}) ->
    if @parent
      @ref = @parent.child(@path)
    else
      @ref = new Firebase(@path)

  child: (path) ->
    @ref.child(path)

Batman.App.syncsWithFirebase = (@firebaseAppName) ->
  @firebaseURL = "https://#{@firebaseAppName}.firebaseio.com/"
  @firebase = new BatFire.Reference(path: @firebaseURL)

class BatFire.Storage extends Batman.StorageAdapter
  constructor: ->
    super
    @firebaseClass = Batman.helpers.pluralize(@model.resourceName)
    #### Should be rewritten as a model mixin
    ####
    @model.encode(@model.primaryKey)

    clearLoaded = @model.clear
    @model.clear = =>
      result = clearLoaded.apply(@model)
      @_listeningToList = false
      delete @model._firebaseListRef
      result

    loadRecords = @model.load
    @model.load = (options, callback) =>
      Batman.developer.warn("Firebase doesn't return all records at once!")
      loadRecords.apply(@model, options, callback)
    ####
    ####

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


