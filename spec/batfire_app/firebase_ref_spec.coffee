describe 'access to firebase reference', ->
  it 'is on App.firebase.ref', ->
    ensureRunning()
    exampleRef = new Firebase(TestApp.get('firebaseURL'))
    appRef = TestApp.get('firebase.ref')
    expect(appRef).toBeDefined()
    expect(appRef.constructor).toEqual(exampleRef.constructor)
