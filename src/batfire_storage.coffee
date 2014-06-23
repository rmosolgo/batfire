
class BatFire.Storage extends Batman.StorageAdapter
  constructor: ->
    super
    firebaseClass = Batman.helpers.pluralize(@model.storageKey || @model.resourceName)
    @model.encode(@model.get('primaryKey'))

    _BatFireClearLoaded = @model.clear
    @model.clear = ->
      result = _BatFireClearLoaded.apply(@)
      ref = @get('ref')
      ref?.off()
      @unset('ref')
      result

    @model.destroyAll = (options={}) ->
      @_doStorageOperation 'destroyAll', options, (err, records, env) ->
        callback?(err, records, env)

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

    @model.prioritizedBy = (accessorName) ->
      @::_priority = -> @get(accessorName)
      @_prioritized = true

    @model.query = (options = {}, callback) ->
      if !@_prioritized
        throw new Error("#{@constructor.name} cant be queried until its priority is defined with `@prioritizedBy(attrName)`! ")
      path = @get('firebasePath')
      ref = Batman.currentApp.get('firebase').child(path)
      for k, v of options
        ref = ref[k](v)

      success = (snapshot) =>
        data = snapshot.val()
        result = (@createFromJSON(item) for id, item of data)
        callback(undefined, result)

      failure = (err) ->
        callback(err, undefined)

      ref.once('value', success, failure)

  _createRef: (env) ->
    try
      firebaseChildPath = env.subject.get('firebasePath')
      ref = Batman.currentApp.get('firebase').child(firebaseChildPath)
      if env.action is 'create'
        ref = ref.push()
    catch e
      env.error = e
    ref

  _listenToList: (model, ref) ->
    ref.on 'child_added', (snapshot) =>
      record = model.createFromJSON(snapshot.val())
    ref.on 'child_removed', (snapshot) =>
      record = model.createFromJSON(snapshot.val())
      model.get('loaded').remove(record)
    ref.on 'child_changed', (snapshot) =>
      record = model.createFromJSON(snapshot.val())
    model.set('ref', ref)


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

  _setOnEnv: (env, next) ->
    payload = env.subject.toJSON()
    callback = (err) ->
      if err
        env.error = err
      next()

    if env.subject.constructor._prioritized
      priority = env.subject._priority()
      env.firebaseRef.setWithPriority(payload, priority, callback)
    else
      env.firebaseRef.set(payload, callback)

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
    @_setOnEnv(env, next)


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
    @_setOnEnv(env, next)

  destroy: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()

  readAll: @skipIfError (env, next) ->
    @_listenToList(env.subject, env.firebaseRef)
    success = (listSnapshot) ->
      listData = listSnapshot.val()
      env.result = (env.subject.createFromJSON(item) for id, item of listData)
      next()
    failure = (err) ->
      env.error = err
      next()
    env.firebaseRef.once('value', success, failure)

  destroyAll: @skipIfError (env, next) ->
    env.firebaseRef.remove (err) ->
      if err
        env.error = err
      next()
