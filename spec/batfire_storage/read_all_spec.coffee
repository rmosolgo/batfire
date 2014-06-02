describe 'readAll', ->
  beforeEach ->
    ensureRunning()
    TestApp.TestModel.clear()
  afterEach -> TestApp.TestModel.destroyAll()

  it 'returns all records and passes the array to the callback', ->
    spyOn(BatFire.Storage.prototype, 'readAll').andCallThrough()
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
            throw error if error?
            expect(rs.length).toEqual(2)
            saved = true

    waitsFor (=> TestApp.TestModel.get('loaded.length') == 2), "Record should be saved",5000

    runs =>
      expect(BatFire.Storage::readAll).toHaveBeenCalled()
      expect(error).toBeFalsy()
      expect(TestApp.TestModel.get('loaded.length')).toEqual(2)

  it 'listens for child_added', ->
    TestApp.TestModel.load()
    ref = TestApp.TestModel.get('ref')
    childRef = ref.push()
    ready = false

    runs ->
      id = childRef.name()
      childRef.set({id: id, name: "Cyclone", type: "Ferret"}, -> ready = true)

    waitsFor -> TestApp.TestModel.get('loaded.length') == 1

    runs ->
      expect(TestApp.TestModel.get('loaded.length')).toEqual(1)

  it 'listens for child_removed', ->
    id = null
    ready = false
    TestApp.TestModel.load()

    runs ->
      loki = new TestApp.TestModel({name: "Max", type: "Ferret"})
      loki.save (err, record) ->
        id = record.get('id')
        TestApp.TestModel.load()
        expect(TestApp.TestModel.get('loaded.length')).toEqual(1)
        ref = TestApp.TestModel.get('ref')
        childRef = ref.child(id)
        childRef.remove ->
          ready = true

    waitsFor -> ready

    runs ->
      expect(TestApp.TestModel.get('loaded.length')).toEqual(0)

  it 'listens for child_changed', ->
    id = null
    ready = false
    TestApp.TestModel.load()

    runs ->
      loki = new TestApp.TestModel({name: "Max", type: "Ferret"})
      loki.save (err, record) ->
        id = record.get('id')
        ref = TestApp.TestModel.get('ref')
        childRef = ref.child("#{id}/name")
        childRef.set 'Cupcake', ->
          ready = true

    waitsFor -> ready

    runs ->
      expect(TestApp.TestModel.get('loaded').get('first').get('name')).toEqual('Cupcake')
