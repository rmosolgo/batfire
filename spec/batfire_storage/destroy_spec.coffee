describe 'destroy', ->
  beforeEach ->
    TestApp.TestModel.clear()
    TestApp.TestModel.destroyAll()

  it 'destroys existing records', ->
    spyOn(BatFire.Storage.prototype, 'destroy').andCallThrough()
    record = newTestRecord(name: "destroy record")
    destroyed = false
    error = null
    destroyedRecord = null

    runs =>
      record.save (err, r) =>
        recordId = r.get('id')
        record.destroy (err, r) =>
          TestApp.TestModel.find recordId, (err, destroyedRecord) =>
            error = err
            destroyedRecord = destroyedRecord
            destroyed = true


    waitsFor (=> destroyed), "Record should be destroyed"

    runs =>
      expect(BatFire.Storage::destroy).toHaveBeenCalled()
      expect(error.message).toMatch(/Record couldn't be found/)
      expect(TestApp.TestModel.get('loaded.length')).toEqual(0)

