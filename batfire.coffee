class @BatFire
  @VERSION = '0.1.0'

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
      @firebaseURL = "https://#{@firebaseAppName}.firebaseio.com/BatFire"
      @set 'firebase', new BatFire.Reference(path: @firebaseURL)

    @syncs = (keypathString, {as}={}) ->
      @_syncKeypaths ?= []
      @_syncKeypaths.push(keypathString)
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @get('firebase').child("syncs/#{firebasePath}")
      syncConstructorName = as
      @observe keypathString, (newValue, oldValue) =>
        return if newValue is oldValue or Batman.typeOf(newValue) is 'Undefined'
        newValue = newValue.toJSON() if newValue?.toJSON
        childRef.set(newValue)
      childRef.on 'value', (snapshot) =>
        value = snapshot.val()
        if syncConstructorName?
          syncConstructor = Batman.currentApp[syncConstructorName]
          value = new syncConstructor(value)
        @set(keypathString, value)

    @_updateFirebaseChild = (keypathString, newValue) ->
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @get('firebase').child("syncs/#{firebasePath}")
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
    firebaseClass = Batman.helpers.pluralize(@model.storageKey || @model.resourceName)
    @model.encode(@model.get('primaryKey'))

    _BatFireClearLoaded = @model.clear
    @model.clear = =>
      result = _BatFireClearLoaded.apply(@model)
      ref = @model.get('ref')
      ref?.off()
      @model.unset('ref')
      result

    @model.classAccessor 'firebasePath', ->
      children = ['records']
      if @get('isScopedToCurrentUser')
        uid = Batman.currentApp.get('currentUser.uid')
        if !uid?
          throw "#{firebaseClass} is scoped to currentUser -- you must be logged in to access it!"
        children.push('scoped')
        children.push(uid)
      children.push(firebaseClass)
      children.join("/")

    @model.accessor 'firebasePath', ->
      children = ['records']
      if @get('isScopedToCurrentUser')
        uid = if @get('isNew')
            Batman.currentApp.get('currentUser.uid')
          else
            @get('created_by_uid')
        if !uid?
          throw "#{firebaseClass} #{@get("id") || 'record'} is scoped to currentUser -- you must be logged in to access them!"
        children.push('scoped')
        children.push(uid)
      children.push(firebaseClass)

      if !@isNew()
        children.push(@get('id'))
      children.join("/")

    @model.encodesTimestamps = ->
      @accessor('_encodesTimestamps', -> true)
      @encode('created_at', 'updated_at', {
        encode: (value) -> value.toISOString()
        decode: (value) -> new Date(value)
        })

  _createRef: (env) ->
    try
      firebaseChildPath = env.subject.get('firebasePath')
      ref = Batman.currentApp.get('firebase').child(firebaseChildPath)
      if env.action is 'create'
        ref = ref.push()
    catch e
      env.error = e
    ref

  _listenToList: (ref, callback) ->
    return if @model.get('ref')
    ref.on 'child_added', (snapshot) =>
      record = @model.createFromJSON(snapshot.val())
    ref.on 'child_removed', (snapshot) =>
      record = @model.createFromJSON(snapshot.val())
      @model.get('loaded').remove(record)
    ref.on 'child_changed', (snapshot) =>
      record = @model.createFromJSON(snapshot.val())
    @model.set('ref', ref)


  @::before 'destroy', 'destroyAll', @skipIfError (env, next) ->
    if env.subject.get('hasUserOwnership')
      if env.action is 'destroyAll'
        env.error = new Error("You can't call destroyAll on these records because some may belong to other users.")
      if env.action is 'destroy' and !env.subject.get('isOwnedByCurrentUser')
        env.error = new Error("You can't destroy this record becasue it doesn't belong to you.")
    next()

  @::before 'create', 'update', 'read', 'destroy', 'readAll', 'destroyAll', @skipIfError (env, next) ->
    env.primaryKey = @model.primaryKey
    env.firebaseRef = @_createRef(env)
    next()

  @::after 'create', 'update', 'read', 'destroy', @skipIfError (env, next) ->
    env.result = env.subject
    next()

  create: @skipIfError (env, next) ->
    firebaseId = env.firebaseRef.name()
    env.subject._withoutDirtyTracking ->
      if env.subject.get('_encodesTimestamps')
        @set('created_at', new Date)
        @set('updated_at', new Date)
      if env.subject.get('_belongsToCurrentUser')
        for attr in BatFire.AuthModelMixin.CREATED_BY_FIELDS
          @set("created_by_#{attr}", Batman.currentApp.get('currentUser').get(attr))
      @set(env.primaryKey, firebaseId)
    env.firebaseRef.set env.subject.toJSON(), (err) ->
      if err
        env.error = err
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
    env.subject._withoutDirtyTracking ->
      if env.subject.get('_encodesTimestamps')
        @set('updated_at', new Date)
    env.firebaseRef.set env.subject.toJSON(), (err) ->
      if err
        env.error = err
      next()

  destroy: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()

  readAll: @skipIfError (env, next) ->
    @_listenToList(env.firebaseRef)
    env.firebaseRef.once 'value', (listSnapshot) =>
      listData = listSnapshot.val()
      env.result = (env.subject.createFromJSON(item) for id, item of listData)
      next()

  destroyAll: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()
class BatFire.User extends Batman.Object

BatFire.AuthAppMixin =
  initialize: ->
    @authorizesWithFirebase = (@providers...) ->
      @set 'currentUser', new BatFire.User
      @on 'run', =>
        @set 'auth', new FirebaseSimpleLogin @get('firebase.ref'), (err, user) =>
          if err?
            throw err
          else
            @_updateCurrentUser(user)

    @_updateCurrentUser = (attrs={}) ->
      @set("currentUser", new BatFire.User(attrs))

    @login = (provider, options={}) ->
      if @providers.length is 1
        provider ?= @providers[0]
      if (@providers.length) and (provider not in @providers)
        throw "Auth provider #{provider} not in whitelisted providers [#{@providers.join(", ")}]"

      @get('auth').login(provider, options)

    @logout = ->
      @get('auth').logout()
      Batman._scopedModels ?= []
      model.clear() for model in Batman._scopedModels
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', ->  !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('loggedIn')

Batman.App.classMixin(BatFire.AuthAppMixin)


class BatFire.CurrentUserValidator extends Batman.Validator
  @triggers 'ownedByCurrentUser'

  validateEach: (errors, record, key, callback) ->
    if !record.get('isNew') # these are only set after create
      if !record.get('hasOwner')
        errors.add('base', "This record doesn't have an owner!")
      else if !record.get('isOwnedByCurrentUser')
        errors.add('base', "You don't own this record!")
    else
      if !Batman.currentApp.get('loggedIn')
        errors.add('base', "You must be logged in to create this!")
    callback()

Batman.Validators.push(BatFire.CurrentUserValidator)

BatFire.AuthModelMixin =
  CREATED_BY_FIELDS: ['uid', 'email', 'username']

  initialize: ->
    @belongsToCurrentUser = ({scoped, ownership}={})->
      for attr in BatFire.AuthModelMixin.CREATED_BY_FIELDS
        do (attr) =>
          accessorName = "created_by_#{attr}"
          @accessor(accessorName, Batman.Model.defaultAccessor) # uses default accessor
          @encode(accessorName)

      @accessor 'hasOwner', -> @get('created_by_uid')?
      @accessor 'isOwnedByCurrentUser', ->
        @get('hasOwner') and @get('created_by_uid') is Batman.currentApp.get('currentUser.uid')

      # used by the storage adapter:
      @set('_belongsToCurrentUser', true)
      @accessor('_belongsToCurrentUser', -> true)

      if ownership
        @validate('created_by_uid',{ownedByCurrentUser: true})
        @set('hasUserOwnership', true) # picked up in the storage adapter
        @accessor 'hasUserOwnership', -> true # picked up in the storage adapter
        @encode('hasUserOwnership', as: 'has_user_ownership')

      if scoped
        Batman._scopedModels ?= []
        Batman._scopedModels.push(@)
        @set('isScopedToCurrentUser', true) # picked up by storage adapter
        @accessor 'isScopedToCurrentUser', -> @constructor.get('isScopedToCurrentUser')



Batman.Model.classMixin(BatFire.AuthModelMixin)
