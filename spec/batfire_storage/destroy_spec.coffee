describe 'destroy', ->
  beforeEach ->
    TestApp.TestModel.clear()
    TestApp.TestModel.destroyAll()

  it 'destroys existing records', ->
    destroySpy = spyOn(TestApp.TestModel.storageAdapter(), 'destroy').andCallThrough()
    record = newTestRecord(name: "destroy record")
    destroyed = false
    error = null
    destroyErr = null

    runs =>
      record.save (err, r) =>
        recordId = r.get('id')
        record.destroy (err, r) =>
          destroyErr = err
          TestApp.TestModel.find recordId, (err, r) =>
            error = err
            destroyed = true

    waitsFor (=> destroyed), "Record should be destroyed"

    runs =>
      expect(destroyErr).toBeUndefined()
      expect(destroySpy).toHaveBeenCalled()
      expect(error.message).toMatch(/Record couldn't be found/)
      expect(TestApp.TestModel.get('loaded.length')).toEqual(0)

