describe 'Model.belongsToCurrentUser', ->
  beforeEach ->
    ensureRunning()
    TestApp._updateCurrentUser({username: "richard_nixon", email: "rnixon@presidency.gov", uid: "12345"})

  describe 'scope: true', ->
    it 'prefixes the storageUrl', -> notImplemented()
    it "doesn't put other peoples' in the loaded set", -> notImplemented()


