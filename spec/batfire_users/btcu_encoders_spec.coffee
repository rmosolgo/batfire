describe 'Model.belongsToCurrentUser', ->
  beforeEach ->
    ensureRunning()
    TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})
    TestApp.TestModel.belongsToCurrentUser()

  describe 'model attributes', ->
    it "on create, stores currentUser uid, username, email on the record", ->
      t = new TestApp.TestModel
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toBeUndefined()
      expect(tJSON["created_by_email"]).toBeUndefined()
      expect(tJSON["created_by_username"]).toBeUndefined()
      t.save()
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toEqual("12345")
      expect(tJSON["created_by_email"]).toEqual("rnixon@presidency.gov")
      expect(tJSON["created_by_username"]).toEqual("richard_nixon")

    it 'can be undefined', ->
      TestApp._updateCurrentUser({})
      t = new TestApp.TestModel
      t.save()
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toBeUndefined()
      expect(tJSON["created_by_email"]).toBeUndefined()
      expect(tJSON["created_by_username"]).toBeUndefined()

    it 'doesnt overwrite undefined when someone signs in', ->
      TestApp._updateCurrentUser({})
      t = new TestApp.TestModel
      t.save()
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toBeUndefined()
      expect(tJSON["created_by_email"]).toBeUndefined()
      expect(tJSON["created_by_username"]).toBeUndefined()
      TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toBeUndefined()
      expect(tJSON["created_by_email"]).toBeUndefined()
      expect(tJSON["created_by_username"]).toBeUndefined()

    it 'doesnt overwrite on later save', ->
      TestApp._updateCurrentUser({})
      t = new TestApp.TestModel
      t.save()
      TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})
      t.save()
      tJSON = t.toJSON()
      expect(tJSON["created_by_uid"]).toBeUndefined()
      expect(tJSON["created_by_email"]).toBeUndefined()
      expect(tJSON["created_by_username"]).toBeUndefined()

  describe 'protected: true', ->
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
