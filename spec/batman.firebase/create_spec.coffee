describe 'create', ->
  beforeEach -> TestModel.destroyAll()
  afterEach -> TestModel.destroyAll()

  it 'creates new records', ->
    spyOn(Batman.Firebase.Storage.prototype, 'create').andCallThrough()
    record = newTestRecord()
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
      expect(@error).toBeFalsy()
      expect(@savedRecord.get('name')).toEqual('new record')

