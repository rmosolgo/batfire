describe 'BatFire.Storage.ModelMixin', ->
  beforeEach -> ensureRunning()

  it 'encodes primaryKey', ->
    pk = TestApp.TestModel.primaryKey
    expect(TestApp.TestModel::_batman.get('encoders').get(pk)).toBeTruthy()

  it 'starts listening on .load', ->
    expect(TestApp.TestModel.get('ref')).toBeFalsy()
    TestApp.TestModel.load()
    expect(TestApp.TestModel.get('ref')).toBeTruthy()

  it 'stops listening on .clear', ->
    TestApp.TestModel.load()
    expect(TestApp.TestModel.get('ref')).toBeTruthy()
    TestApp.TestModel.clear()
    expect(TestApp.TestModel.get('ref')).toBeFalsy()

  describe 'encodesTimestamps', ->
    afterEach: -> TestApp.TimestampModel.destroyAll()

    it 'on create, sets created_at and updated_at to ISO string', ->
      tm = new TestApp.TimestampModel
      expect(tm.toJSON().created_at).toBeUndefined()
      ready = false

      runs =>
        tm.save =>
          @actualCreatedAt = (new Date).toISOString()
          @createdAt = tm.toJSON().created_at
          @updatedAt = tm.toJSON().updated_at
          ready = true

      waitsFor -> ready == true

      runs =>
        expect(@createdAt.substr(0,20)).toEqual(@actualCreatedAt.substr(0,20))
        expect(@updatedAt.substr(0,22)).toEqual(@createdAt.substr(0,22))

    it 'on update, sets updated_at to ISO string but doesnt change created_at', ->
      tm = new TestApp.TimestampModel
      expect(tm.toJSON().created_at).toBeUndefined()
      ready = false

      runs =>
        tm.save =>
          @actualCreatedAt = (new Date).toISOString()
          @createdAt = tm.toJSON().created_at
          @updatedAt = tm.toJSON().updated_at
          setTimeout =>
              tm.save =>
                @laterCreatedAt = tm.toJSON().created_at
                @laterUpdatedAt = tm.toJSON().updated_at
                ready = true
            , 200

      waitsFor -> ready == true

      runs =>
        expect(@createdAt.substr(0,20)).toEqual(@actualCreatedAt.substr(0,20))
        expect(@updatedAt).not.toEqual(@laterUpdatedAt)
        expect(@createdAt.substr(0,22)).toEqual(@laterCreatedAt.substr(0,22))