
class Batman.Firebase

class Batman.Firebase.Reference
  constructor: ({@path, @parent}) ->
    if @parent
      @ref = @parent.child(@path)
    else
      @ref = new Firebase(@path)

  child: (path) ->
    @ref.child(path)

class Batman.Firebase.Storage extends Batman.StorageAdapter
  constructor: ->
    super
    @firebaseClass = Batman.helpers.pluralize(@model.resourceName)


  @::before 'create', 'update', 'read', 'destroy', 'readAll', @skipIfError (env, next) ->
    @firebaseListRef ||= Batman.currentApp.firebase.child(@firebaseClass)
    if env.subject.get('id')
      env.firebaseRef = @firebaseListRef.child(env.subject.get('id'))
    else if env.action is 'readAll'
      env.firebaseRef = @firebaseListRef
    else
      env.firebaseRef = @firebaseListRef.push()
    next()

  @::after 'create', 'update', 'read', 'destroy', @skipIfError (env, next) ->
    env.result = env.subject
    console.log "successful #{env.action}!"
    next()

  @::after 'readAll', @skipIfError (env, next) ->
    env.result = @getRecordsFromData(env.recordsAttributes, env.subject)
    console.log env
    next()

  create: @skipIfError (env, next) ->
    env.firebaseRef.set env.subject.toJSON(), (err) ->
      if err
        env.error = err
        console.log err
      else
        id = env.firebaseRef.name()
        console.log 'id', id
        env.subject._withoutDirtyTracking -> @set('id', id)
      next()

  read: @skipIfError (env, next) ->
    env.firebaseRef.once 'value', (snapshot) ->
      env.subject._withoutDirtyTracking -> @fromJSON snapshot.val()
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
    env.firebaseRef.once 'value', (snapshot) ->
      env.recordsAttributes = snapshot.val()
      next()

  destroyAll: ->


Batman.App.syncs = (@firebaseAppName) ->
  @firebaseURL = "https://#{@firebaseAppName}.firebaseio.com/"
  @firebase = new Batman.Firebase.Reference(path: @firebaseURL)
  console.log "Syncing to #{@firebaseURL}"
