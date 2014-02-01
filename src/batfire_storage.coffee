
class BatFire.Storage extends Batman.StorageAdapter
  constructor: ->
    super
    @firebaseClass = firebaseClass = Batman.helpers.pluralize(@model.storageKey || @model.resourceName)
    @model.encode(@model.get('primaryKey'))

    _BatFireClearLoaded = @model.clear
    @model.clear = =>
      result = _BatFireClearLoaded.apply(@model)
      ref = @model.get('ref')
      ref?.off()
      @model.unset('ref')
      result

    @model.generateFirebasePath = ->
      children = []
      if @get('isScopedToCurrentUser')
        uid = Batman.currentApp.get('currentUser.uid')
        if !uid?
          throw "#{@model.resourceName} is scoped to currentUser -- you must be logged in to access it!"
        children.push(uid)
      children.push(firebaseClass)
      children.join("/")

    @model::generateFirebasePath = ->
      children = []
      if @get('isScopedToCurrentUser')
        uid = @get('created_by_uid')
        if !uid?
          throw "#{@constructor.resourceName} is scoped to currentUser -- you must be logged in to access it!"
        children.push(uid)
      children.push(firebaseClass)
      if !@isNew()
        children.push(@get('id'))
      children.join("/")

  _createRef: (env) ->
    firebaseChildPath = env.subject.generateFirebasePath()
    Batman.currentApp.get('firebase').child(firebaseChildPath)


  _listenToList: (ref) ->
    if !@model.get('ref')
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
    ref = @_createRef(env)
    if env.action is 'create'
      env.firebaseRef = ref.push()
    else
      env.firebaseRef = ref
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
      next()

  destroy: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()

  readAll: @skipIfError (env, next) ->
    @_listenToList(env.firebaseRef)
    next()

  destroyAll:  @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()
