describe 'read', ->
  afterEach -> TestApp.TestModel.destroyAll()
  it 'returns saved record', ->
    spyOn(BatFire.Storage.prototype, 'read').andCallThrough()
    record = newTestRecord()
    @saved = false
    @savedRecord = null
    @error = null

    runs =>
      record.save (err, r) =>
        recordId = r.get('id')
        TestApp.TestModel.clear()
        TestApp.TestModel.find recordId, (err2, record2) =>
          @error = err2
          @savedRecord = record2
          @saved = true


    waitsFor (=> @saved), "Record should be saved"

    runs =>
      expect(@error).toBeFalsy()
      expect(@savedRecord.get('name')).toEqual('new record')
