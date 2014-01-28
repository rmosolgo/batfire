describe 'readAll', ->
  beforeEach -> TestModel.destroyAll()
  afterEach -> TestModel.destroyAll()

  it 'returns all records', ->
    spyOn(Batman.Firebase.Storage.prototype, 'readAll').andCallThrough()
    @saved = false
    @error = null
    ids = []

    runs =>
      newTestRecord().save (err, r) =>
        @error ||= err
        ids.push r.get('id')
        newTestRecord(name: "other name").save (err2, r2) =>
          ids.push r2.get('id')
          @error ||= err2
          TestModel.clear()
          console.log 'loading'
          TestModel.load (e, rs)=>
            console.log 'loaded records', rs
            @error ||= e
            console.log 'readAll error ', @error
            throw @error if @error
            @saved = true

    waitsFor (=> @saved), "Record should be saved",10000

    runs =>
      expect(@error).toBeFalsy()
      expect(TestModel.get('all.length')).toEqual(2)
