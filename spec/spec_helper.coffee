class window.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist Batman.Firebase.Storage
  @encode 'name'

  @destroyAll: (callback) ->
    # return @load (err, records) ->
    #   records.forEach (m) -> m?.destroy()
    options = undefined
    @_doStorageOperation 'destroyAll', options, (err, records, env) =>
        callback?(err, records, env)


window.newTestRecord = (attrs) ->
  record = new TestModel(name: "new record")
  # record.set 'file', new Blob(["My file content!"], type: "text/plain")
  # record.set 'filename', 'test.txt'
  record.updateAttributes(attrs)
  record
