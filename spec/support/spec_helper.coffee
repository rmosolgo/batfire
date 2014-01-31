class @TestApp extends Batman.App
  @syncsWithFirebase 'batman-dev'
  @authorizesWithFirebase('github')
  @syncs 'someInteger'
  @syncs 'someObject'
  @syncs 'someBatmanObject', as: Batman.Object

class TestApp.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist BatFire.Storage
  @encode 'name'

  @destroyAll: (callback) ->
    # return @load (err, records) ->
    #   records.forEach (m) -> m?.destroy()
    options = undefined
    @_doStorageOperation 'destroyAll', options, (err, records, env) =>
        callback?(err, records, env)

@notImplemented = ->
  console.warn "Not Implemented"

appIsRunning = false
window.ensureRunning = ->
  if !appIsRunning
    TestApp.run()
    appIsRunning = true

window.newTestRecord = (attrs) ->
  ensureRunning()
  record = new TestApp.TestModel(name: "new record")
  record.updateAttributes(attrs)
  record
