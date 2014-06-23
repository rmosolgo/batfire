class @TestApp extends Batman.App
  @syncsWithFirebase 'batman-dev'
  @authorizesWithFirebase('github')
  @syncs 'someInteger'
  @syncs 'someObject'
  @syncs 'someTestModel', as: "TestModel"

class TestApp.TestModel extends Batman.Model
  @resourceName: 'test_model'
  @persist BatFire.Storage
  @encode 'name', 'type'

class TestApp.SafeModel extends TestApp.TestModel
  @resourceName: 'safe_model'
  @belongsToCurrentUser ownership: true
  @persist BatFire.Storage

class TestApp.ScopedModel extends TestApp.TestModel
  @resourceName: 'scoped_model'
  @belongsToCurrentUser scoped: true
  @persist BatFire.Storage

class TestApp.TimestampModel extends TestApp.TestModel
  @resourceName: 'timestamp_model'
  @persist BatFire.Storage
  @encodesTimestamps()

class TestApp.PrioritizedModel extends TestApp.TestModel
  @resourceName: 'prioritized_model'
  @persist BatFire.Storage
  @encode 'name'
  @prioritizedBy('name')

@notImplemented = ->
  console.warn "Not Implemented"

appIsRunning = false
@ensureRunning = ->
  if !appIsRunning
    TestApp.run()
    appIsRunning = true

@ensureStopped = ->
  Batman.currentApp?.stop()

@newTestRecord = (attrs) ->
  ensureRunning()
  record = new TestApp.TestModel(name: "new record")
  record.updateAttributes(attrs)
  record
