describe 'Model.belongsToCurrentUser', ->
  beforeEach ->
    ensureRunning()
    TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})

  describe 'ownership: true', ->
    it "throws error if record creator isn't currentUser", ->
      sm = new TestApp.SafeModel
      smId = null
      foundRecord = null
      sm.validate()
      expect(sm.get('errors.length')).toEqual(0)

      runs ->
        sm.save (err, record) ->
          smId = record.get('id')
          TestApp.SafeModel.clear()
          TestApp._updateCurrentUser({})
          TestApp.SafeModel.find smId, (err, record) ->
            foundRecord = record

      waitsFor (-> foundRecord?), "Record is saved then found"

      runs ->
        expect(foundRecord.get('isOwnedByCurrentUser')).toBe(false)
        expect(foundRecord.toJSON()["created_by_uid"]).toEqual("12345")
        expect(TestApp.get('currentUser.uid')).toBeFalsy()
        foundRecord.validate()
        expect(foundRecord.get('errors.length')).toEqual(1)
        expect(foundRecord.get('errors.first.fullMessage')).toMatch(/You don't own this/)
        foundRecord.destroy (err, record) ->
          expect(record).toBeFalsy()
          expect(err?.message).toMatch(/it doesn't belong to you/)

    it "doesnt throw error if record creator is currentUser", ->
      sm = new TestApp.SafeModel
      smId = null
      foundRecord = null
      sm.validate()
      expect(sm.get('errors.length')).toEqual(0)

      runs ->
        sm.save (err, record) ->
          smId = record.get('id')
          TestApp.SafeModel.clear()
          TestApp.SafeModel.find smId, (err, record) ->
            foundRecord = record

      waitsFor (-> foundRecord?), "Record is saved then found"

      runs ->
        expect(foundRecord.get('isOwnedByCurrentUser')).toBe(true)
        expect(foundRecord.toJSON()["created_by_uid"]).toEqual("12345")
        expect(TestApp.get('currentUser.uid')).toEqual("12345")
        foundRecord.validate()
        expect(foundRecord.get('errors.length')).toEqual(0)
        foundRecord.destroy (err, record) ->
          expect(err).toBeFalsy()
