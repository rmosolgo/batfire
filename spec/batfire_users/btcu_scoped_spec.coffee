describe 'Model.belongsToCurrentUser', ->
  beforeEach ->
    ensureRunning()
    TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})

  describe 'scope: true', ->
    it 'prefixes the storageUrl', ->
      modelPath = TestApp.ScopedModel.generateFirebasePath()
      expect(modelPath).toEqual("12345/scoped_models")

      recordPath = TestApp.ScopedModel::generateFirebasePath()
      expect(recordPath).toEqual("12345/scoped_models")

      pseudoSavedRecord = TestApp.ScopedModel.createFromJSON({id: 5})
      savedRecordPath = pseudoSavedRecord.generateFirebasePath()
      expect(savedRecordPath).toEqual("12345/scoped_models/5")

    it "doesn't put other peoples' in the loaded set", ->
      sm = new TestApp.ScopedModel(name: "Whiskers", type: "Mouse")
      ready = false
      runs ->
        sm.save (err, record) ->
          throw err if err?
          expect(TestApp.ScopedModel.get('all.length')).toEqual(1)
          TestApp.ScopedModel.clear()
          expect(TestApp.ScopedModel.get('loaded.length')).toEqual(0)
          TestApp._updateCurrentUser({username: "woodrow_wilson", email: "wwilson@presidency.gov", uid: "54321"})
          TestApp.ScopedModel.load()
          setTimeout ->
              ready = true
            , 100

      waitsFor -> ready

      runs ->
        expect(TestApp.ScopedModel.generateFirebasePath()).toEqual("54321/scoped_models")
        expect(TestApp.ScopedModel.get('all.length')).toEqual(0)

    it "clears the loaded set on logout", ->
      sm = new TestApp.ScopedModel(name: "Whiskers", type: "Mouse")
      ready = false

      runs ->
        sm.save (err, record) ->
          expect(TestApp.ScopedModel.get('all.length')).toEqual(1)
          TestApp.logout()
          TestApp.ScopedModel.get('all')
          setTimeout ->
              ready = true
            , 100

      waitsFor -> ready

      runs ->
        expect(TestApp.ScopedModel.get('all.length')).toEqual(0)

