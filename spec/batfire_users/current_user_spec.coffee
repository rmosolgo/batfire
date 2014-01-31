describe 'currentUser', ->
  afterEach -> TestApp.logout()
  # This spec just isn't sustainable...
  # it 'has all the user stuff', ->
  #   TestApp.login()
  #   cU = TestApp.get('currentUser')

  #   if !cU.toJSON()["provider"]?
  #     throw "Open Karma debug to sign in!"
  #   for key in ["uid", "email", "accessToken", "displayName", "provider", "username"]
  #     expect(cU.get(key)).toBeDefined()

  it 'is observable', ->
    emailSpy = jasmine.createSpy()
    TestApp.observe 'currentUser.email', (newValue, oldValue) ->
      emailSpy(newValue)
    TestApp._updateCurrentUser({email: "google@gmail.com"})
    email = TestApp.get('currentUser.email')
    expect(emailSpy).toHaveBeenCalledWith(email)

describe 'loggedIn/loggedOut', ->
  it 'watches for currentUser', ->
    expect(TestApp.get('loggedIn')).toBe(false)
    expect(TestApp.get('loggedOut')).toBe(true)
    TestApp.set('currentUser.uid', 'blah blah blah')
    expect(TestApp.get('loggedIn')).toBe(true)
    expect(TestApp.get('loggedOut')).toBe(false)
    TestApp.unset('currentUser')
    expect(TestApp.get('loggedIn')).toBe(false)
    expect(TestApp.get('loggedOut')).toBe(true)
