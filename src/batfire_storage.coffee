
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
          debugger
          console.log @toJSON()
          throw "#{firebaseClass} #{@get("id") || 'record'} is scoped to currentUser -- you must be logged in to access them!"
        children.push('scoped')
        children.push(uid)
      children.push(firebaseClass)

      if !@isNew()
        children.push(@get('id'))
      children.join("/")

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
