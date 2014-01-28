describe 'create', ->
  it 'creates new records', ->
    spyOn(Batman.Firebase.Storage.prototype, 'create').andCallThrough()
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
      expect(Batman.Firebase.Storage::create).toHaveBeenCalled()
      expect(@error).toBeFalsy()
      expect(@savedRecord.get('name')).toEqual('created record')
      record.destroy()

