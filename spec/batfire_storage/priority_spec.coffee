describe 'prioritizedBy', ->
  afterEach -> TestApp.PrioritizedModel.destroyAll()

  it 'creates new records with priority', ->
    record3 = new TestApp.PrioritizedModel(name: "3 record")
    record1 = new TestApp.PrioritizedModel(name: "1 record")
    record2 = new TestApp.PrioritizedModel(name: "2 record")
    @saved = false

    runs =>
      record1.save (err, r) =>
        record3.save (err, r) =>
          record2.save (err, r) =>
            TestApp.PrioritizedModel.clear()
            TestApp.PrioritizedModel.load (err, records) =>
              @results = records
              @saved = true

    waitsFor (=> @saved), "Record should be saved"

    runs =>
      expect(@results[0].get('name')).toEqual("1 record")
      expect(@results[1].get('name')).toEqual("2 record")
      expect(@results[2].get('name')).toEqual("3 record")


  it 'updates records with priority', ->
    record3 = new TestApp.PrioritizedModel(name: "3 record")
    record1 = new TestApp.PrioritizedModel(name: "1 record")
    record2 = new TestApp.PrioritizedModel(name: "2 record")
    @saved = false

    runs =>
      record1.save (err, r) =>
        record3.save (err, r) =>
          record2.save (err, r) =>
            r.set('name', '6 record')
            r.save (err, r) =>
              TestApp.PrioritizedModel.clear()
              TestApp.PrioritizedModel.load (err, records) =>
                @results = records
                @saved = true

    waitsFor (=> @saved), "Record should be saved"

    runs =>
      expect(@results[0].get('name')).toEqual("1 record")
      expect(@results[1].get('name')).toEqual("3 record")
      expect(@results[2].get('name')).toEqual("6 record")

  describe 'Model.query', ->
    beforeEach ->
      record3 = new TestApp.PrioritizedModel(name: "3 record")
      record1 = new TestApp.PrioritizedModel(name: "1 record")
      record2 = new TestApp.PrioritizedModel(name: "2 record")
      record4 = new TestApp.PrioritizedModel(name: "4 record")
      saved = false
      runs ->
        record1.save (err, r) =>
          record3.save (err, r) =>
            record2.save (err, r) =>
              record4.save (err, r) =>
                TestApp.PrioritizedModel.clear()
                saved = true

      waitsFor (-> saved), "everything is setup", 1000

    it 'works with limit', ->
      query = null
      runs ->
        TestApp.PrioritizedModel.query {limit: 1}, (err, q) -> query = q

      waitsFor (-> query), "Query is run"

      runs ->
        expect(query.length).toEqual(1)
        expect(query.map((r) -> r.get('name'))).toEqual(["4 record"])

    it 'works with startAt/endAt', ->
      query = null
      runs ->
        TestApp.PrioritizedModel.query {startAt: "1", endAt: "2 z"}, (err, q) -> query = q

      waitsFor (-> query), "Query is run"

      runs ->
        expect(query.length).toEqual(2)
        expect(query.map((r) -> r.get('name'))).toEqual(["1 record", "2 record"])

    it 'works with limit + startAt/endAt', ->
      query = null
      runs ->
        TestApp.PrioritizedModel.query {startAt: "3", limit: 1}, (err, q) -> query = q

      waitsFor (-> query), "Query is run"

      runs ->
        expect(query.length).toEqual(1)
        expect(query.map((r) -> r.get('name'))).toEqual(["3 record"])



