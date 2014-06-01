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

