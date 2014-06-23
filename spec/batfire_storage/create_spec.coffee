describe 'create', ->
  afterEach ->
    TestApp.TestModel.destroyAll()
    TestApp.PrioritizedModel.destroyAll()

  it 'creates new records', ->
    createSpy = spyOn(TestApp.TestModel.storageAdapter(), 'create').andCallThrough()
    record = newTestRecord(name: "created record")
    @saved = false
    @savedRecord = null
    @error = null

    runs =>
      record.save (err, r) =>
        @error = err
        @savedRecord = r
        @saved = true

    waitsFor (=> @saved), "Record should be saved"

    runs =>
      expect(createSpy).toHaveBeenCalled()
      expect(@error).toBeFalsy()
      expect(@savedRecord.get('name')).toEqual('created record')



