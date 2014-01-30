class @TestApp extends Batman.App
  @syncsWithFirebase 'batman-dev'

  @syncs 'someInteger'
  @syncs 'someObject'
  @syncs 'someBatmanObject', as: Batman.Object

class TestApp.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist BatFire.Storage
  @encode 'name', 'id'

  @destroyAll: (callback) ->
    # return @load (err, records) ->
    #   records.forEach (m) -> m?.destroy()
    options = undefined
    @_doStorageOperation 'destroyAll', options, (err, records, env) =>
        callback?(err, records, env)

@notImplemented = ->
  console.warn "Not Implemented"

appIsRunning = false
window.newTestRecord = (attrs) ->
  if !appIsRunning
    TestApp.run()
    appIsRunning = true
  record = new TestApp.TestModel(name: "new record")
  record.updateAttributes(attrs)
  record
