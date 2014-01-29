describe 'update', ->
  afterEach -> TestApp.TestModel.destroyAll()

  it 'saves existing records', ->
    spyOn(BatFire.Storage.prototype, 'update').andCallThrough()
    record = newTestRecord('update record')
    @saved = false
    @savedRecord = null
    @error = null

    runs =>
      record.save (err, r) =>
        recordId = r.get('id')
        TestApp.TestModel.clear()
        TestApp.TestModel.find recordId, (err2, record2) =>
          throw err2 if err2
          record2.set('name', 'updated record name')
          record2.save (err3, record3) =>
            throw err3 if err3
            TestApp.TestModel.clear()
            TestApp.TestModel.find recordId, (err4, record4) =>
              @error = err4
              @savedRecord = record4
              @saved = true

    waitsFor (=> @saved), "Record should be saved"

    runs =>
      expect(@error).toBeFalsy()
      expect(@savedRecord.get('name')).toEqual('updated record name')
