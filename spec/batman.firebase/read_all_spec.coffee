describe 'readAll', ->
  afterEach -> TestApp.TestModel.destroyAll()

  it 'returns all records', ->
    spyOn(Batman.Firebase.Storage.prototype, 'readAll').andCallThrough()
    saved = false
    error = null
    ids = []

    runs =>

      newTestRecord(name: "saved record").save (err, r) =>
        error ||= err
        ids.push r.get('id')
        newTestRecord(name: "other name").save (err2, r2) =>
          ids.push r2.get('id')
          error ||= err2
          TestApp.TestModel.clear()
          TestApp.TestModel.load (e, rs) =>
            error ||= e
            saved = true

    waitsFor (=> TestApp.TestModel.get('loaded.length') == 2), "Record should be saved",5000

    runs =>
      expect(Batman.Firebase.Storage::readAll).toHaveBeenCalled()
      expect(error).toBeFalsy()
      expect(TestApp.TestModel.get('loaded.length')).toEqual(2)
