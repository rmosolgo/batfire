class @BatFire

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
      @set 'firebase', new BatFire.Reference(path: @firebaseURL)

    @syncs = (keypathString, {as}={}) ->
      @_syncKeypaths ?= []
      @_syncKeypaths.push(keypathString)
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @get('firebase').child("BatFire/#{firebasePath}")
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
      childRef = @get('firebase').child("BatFire/#{firebasePath}")
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
  constructor: ->
    super
    @firebaseClass = Batman.helpers.pluralize(@model.resourceName)
    @model.encode(@model.get('primaryKey'))

    _BatFireClearLoaded = @model.clear
    @model.clear = =>
      result = _BatFireClearLoaded.apply(@model)
      @_listeningToList = false
      delete @model._firebaseListRef
      result

  _listenToList: ->
    if !@_listeningToList
      @model._firebaseListRef ?= Batman.currentApp.get('firebase').child(@firebaseClass)
      @model._firebaseListRef.on 'child_added', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
      @model._firebaseListRef.on 'child_removed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
        @model.get('loaded').remove(record)
      @model._firebaseListRef.on 'child_changed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
    @_listeningToList = true

  @::before 'readAll', @skipIfError (env, next) ->
    Batman.developer.warn("Firebase doesn't return all records at once!")
    next()

  @::before 'create', 'update', 'read', 'destroy', 'readAll', 'destroyAll', @skipIfError (env, next) ->
    env.primaryKey = @model.primaryKey
    @model._firebaseListRef ?= Batman.currentApp.get('firebase').child(@firebaseClass)
    if env.subject.get(env.primaryKey)?
      env.firebaseRef = @model._firebaseListRef.child(env.subject.get(env.primaryKey))
    else if env.action is 'readAll' or env.action is 'destroyAll'
      env.firebaseRef = @model._firebaseListRef
    else
      env.firebaseRef = @model._firebaseListRef.push()
    next()

  @::after 'create', 'update', 'read', 'destroy', @skipIfError (env, next) ->
    env.result = env.subject
    next()

  @::after 'readAll', @skipIfError (env, next) ->
    env.result = []
    next()

  create: @skipIfError (env, next) ->
    firebaseId = env.firebaseRef.name()
    env.subject._withoutDirtyTracking -> @set(env.primaryKey, firebaseId)
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
class BatFire.User extends Batman.Object

BatFire.AppUserMixin =
  initialize: ->
    @authorizesWithFirebase = (@defaultProviderString=null) ->
      @set 'currentUser', new BatFire.User
      @on 'run', =>
        @set 'auth', new FirebaseSimpleLogin @get('firebase.ref'), (err, user) =>
          if err?
            throw err
          else
            @_updateCurrentUser(user)

    @_updateCurrentUser = (attrs) ->
      @get('currentUser').mixin(attrs)

    @login = (provider, options={}) ->
      provider ?= @defaultProviderString
      @get('auth').login(provider, options)

    @logout = ->
      @get('auth').logout()
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', -> !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('currentUser.uid')

Batman.App.classMixin(BatFire.AppUserMixin)
