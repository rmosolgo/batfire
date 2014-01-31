describe 'BatFire.Storage.ModelMixin', ->
  beforeEach -> ensureRunning()

  it 'encodes primaryKey', ->
    pk = TestApp.TestModel.primaryKey
    expect(TestApp.TestModel::_batman.get('encoders').get(pk)).toBeTruthy()

  it 'starts listening on .load', ->
    expect(TestApp.TestModel.storageAdapter()._listeningToList).toBeFalsy()
    TestApp.TestModel.load()
    expect(TestApp.TestModel.storageAdapter()._listeningToList).toBeTruthy()

  it 'stops listening on .clear', ->
    TestApp.TestModel.load()
    expect(TestApp.TestModel.storageAdapter()._listeningToList).toBeTruthy()
    TestApp.TestModel.clear()
    expect(TestApp.TestModel.storageAdapter()._listeningToList).toBeFalsy()
