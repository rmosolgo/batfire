class @BatFire
  @VERSION = '0.0.1'

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
      @model.unset('ref')
      result

  _createRef: ->
    Batman.currentApp.get('firebase').child(@firebaseClass)


  _listenToList: ->
    if !@model.get('ref')
      ref = @_createRef()
      ref.on 'child_added', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
      ref.on 'child_removed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
        @model.get('loaded').remove(record)
      ref.on 'child_changed', (snapshot) =>
        record = @model.createFromJSON(snapshot.val())
      @model.set('ref', ref)

  @::before 'create', 'update', 'read', 'destroy', 'readAll', 'destroyAll', @skipIfError (env, next) ->
    env.primaryKey = @model.primaryKey
    ref = @model.get('ref') || @_createRef()
    if env.subject.get(env.primaryKey)?
      env.firebaseRef = ref.child(env.subject.get(env.primaryKey))
    else if env.action is 'readAll' or env.action is 'destroyAll'
      env.firebaseRef = ref
    else
      env.firebaseRef = ref.push()
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
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', ->  !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('loggedIn')

Batman.App.classMixin(BatFire.AuthAppMixin)


class BatFire.CurrentUserValidator extends Batman.Validator
  @triggers 'ownedByCurrentUser'

  validateEach: (errors, record, key, callback) ->
    if !record.isNew() # only validates existing records
      if !record.get('hasOwner')
        errors.add('created_by_uid', "This record doesn't have an owner!")
      else if !record.get('ownedByCurrentUser')
        errors.add('created_by_uid', "You don't own this record!")
    callback()

Batman.Validators.push(BatFire.CurrentUserValidator)

BatFire.AuthModelMixin =
  initialize: ->
    @belongsToCurrentUser = ({scopes, ownership}={})->
      for attr in ['uid', 'email', 'username']
        do (attr) =>
          accessorName = "created_by_#{attr}"
          @accessor accessorName,
            get: ->
              @_currentUserAttrs ?= {}
              @_currentUserAttrs[attr] ?= Batman.currentApp.get("currentUser.#{attr}")
            set: (key, value) ->
              @_currentUserAttrs ?= {}
              @_currentUserAttrs[attr] = value

          @encode accessorName

      if ownership
        @validate('created_by_uid',{ownedByCurrentUser: true})

    @accessor 'hasOwner', -> @get('created_by_uid')?
    @accessor 'ownedByCurrentUser', ->
      @get('created_by_uid') and @get('created_by_uid') is Batman.currentApp.get('currentUser.uid')

Batman.Model.classMixin(BatFire.AuthModelMixin)
