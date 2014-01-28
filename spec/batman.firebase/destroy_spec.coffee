describe 'destroy', ->
  beforeEach -> TestModel.destroyAll()
  afterEach -> TestModel.destroyAll()

  it 'saves existing records', ->
    spyOn(Batman.Firebase.Storage.prototype, 'destroy').andCallThrough()
    record = newTestRecord()
    @destroyed = false
    @error = null
    @destroyedRecord = null

    runs =>
      record.save (err, r) =>
        recordId = r.get('id')
        record.destroy (err, r) =>
          TestModel.find recordId, (err, destroyedRecord) =>
            @error = err
            @destroyedRecord = destroyedRecord
            @destroyed = true


    waitsFor (=> @destroyed), "Record should be destroyed"

    runs =>
      expect(@error.message).toMatch(/Record couldn't be found/)
      expect(TestModel.get('all.length')).toEqual(0)

