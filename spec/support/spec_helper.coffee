class @TestApp extends Batman.App
  @syncsWithFirebase 'batman-dev'
  @authorizesWithFirebase('github')
  @syncs 'someInteger'
  @syncs 'someObject'
  @syncs 'someTestModel', as: "TestModel"

class TestApp.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist BatFire.Storage
  @encode 'name', 'type'
  @destroyAll: (callback) ->
    # return @load (err, records) ->
    #   records.forEach (m) -> m?.destroy()
    options = undefined
    @_doStorageOperation 'destroyAll', options, (err, records, env) =>
        callback?(err, records, env)

class TestApp.SafeModel extends TestApp.TestModel
  @belongsToCurrentUser ownership: true

class TestApp.ScopedModel extends TestApp.TestModel
  @belongsToCurrentUser scoped: true


@notImplemented = ->
  console.warn "Not Implemented"

appIsRunning = false
@ensureRunning = ->
  if !appIsRunning
    TestApp.run()
    appIsRunning = true

@ensureStopped = ->
  Batman.currentApp?.stop()

@newTestRecord = (attrs) ->
  ensureRunning()
  record = new TestApp.TestModel(name: "new record")
  record.updateAttributes(attrs)
  record
