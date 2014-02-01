describe 'login', ->
  beforeEach -> ensureStopped()
  it 'uses the default provider', ->
    TestApp.authorizesWithFirebase("github")
    TestApp.run()
    spyOn(TestApp.get('auth'), 'login')
    TestApp.login()
    expect(TestApp.get('auth').login).toHaveBeenCalledWith('github', {})


  it 'takes a any provider', ->
    TestApp.authorizesWithFirebase()
    TestApp.run()

    spyOn(TestApp.get('auth'), 'login')
    TestApp.login('facebook')
    expect(TestApp.get('auth').login).toHaveBeenCalledWith('facebook', {})

  it 'validates provider in a given list', ->
    TestApp.authorizesWithFirebase('facebook', 'github')
    TestApp.run()

    spyOn(TestApp.get('auth'), 'login')
    error = false
    try
      TestApp.login('twitter')
    catch e
      error = e
    finally
      expect(error).toMatch(/not in whitelisted providers/)
      expect(TestApp.get('auth').login).not.toHaveBeenCalledWith('twitter', {})

  it 'returns providers as .providers', ->
    TestApp.authorizesWithFirebase('twitter', 'github')
    expect(TestApp.get('providers')).toEqual(['twitter', 'github'])

describe 'logout', ->
  it 'empties App.currentUser', ->
    ensureRunning()
    TestApp._updateCurrentUser({uid: "65432"})
    TestApp.logout()
    expect(TestApp.get('currentUser.uid')).toBeUndefined()
    expect(TestApp.get('loggedOut')).toBe(true)
    expect(TestApp.get('loggedIn')).toBe(false)
