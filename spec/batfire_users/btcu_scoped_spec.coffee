describe 'Model.belongsToCurrentUser', ->
  beforeEach ->
    ensureRunning()
    TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})
    TestApp.ScopedModel.get('all') # I'm puzzled, but for some reason this has to be here or else Model.all.length gets out of whack (even though the Set has the right members)

  describe 'scope: true', ->
    it 'prefixes the storageUrl', ->
      modelPath = TestApp.ScopedModel.get('firebasePath')
      expect(modelPath).toEqual("records/scoped/12345/scoped_models")

      recordPath = (new TestApp.ScopedModel).get('firebasePath')
      expect(recordPath).toEqual("records/scoped/12345/scoped_models")

      pseudoSavedRecord = TestApp.ScopedModel.createFromJSON({id: 5, created_by_uid: "12345"})
      savedRecordPath = pseudoSavedRecord.get('firebasePath')
      expect(savedRecordPath).toEqual("records/scoped/12345/scoped_models/5")
      TestApp.ScopedModel.clear()

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
            , 200

      waitsFor (-> ready), 1000


      runs ->
        expect(TestApp.ScopedModel.get('firebasePath')).toEqual("records/scoped/54321/scoped_models")
        expect(TestApp.ScopedModel.get('all.length')).toEqual(0)
        sm.destroy()

    it "clears the loaded set on logout", ->
      ready = false
      sm = new TestApp.ScopedModel(name: "Fido", type: "Dog")

      runs ->
        sm.save (err, record) ->
          throw err if err?
          expect(TestApp.ScopedModel.get('all.length')).toEqual(1)
          TestApp.logout()
          TestApp.ScopedModel.load()
          setTimeout ->
              ready = true
            , 200

      waitsFor (-> ready), 1000

      runs ->
        expect(TestApp.ScopedModel.get('all.length')).toEqual(0)
        sm.destroy()
