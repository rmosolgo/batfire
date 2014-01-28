class @TestApp extends Batman.App
  @syncsWithFirebase 'batman-dev'


class TestApp.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist Batman.Firebase.Storage
  @encode 'name', 'id'

  @destroyAll: (callback) ->
    # return @load (err, records) ->
    #   records.forEach (m) -> m?.destroy()
    options = undefined
    @_doStorageOperation 'destroyAll', options, (err, records, env) =>
        callback?(err, records, env)


appIsRunning = false
window.newTestRecord = (attrs) ->
  if !appIsRunning
    TestApp.run()
  record = new TestApp.TestModel(name: "new record")
  record.updateAttributes(attrs)
  record