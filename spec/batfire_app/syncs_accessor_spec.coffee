describe 'App.syncs', ->
  it 'is defined', ->
    expect(TestApp.syncs).toBeDefined()

  describe 'simple values', ->
    it 'responds to changes from outside', ->
      TestApp.set('someInteger', 3)
      someIntegerSpy = jasmine.createSpy()
      TestApp.observe 'someInteger', ->
        someIntegerSpy()

      childRef = TestApp.firebase.child("syncs/someInteger")
      ready = false

      runs ->
        childRef.set(5, -> ready = true)

      waitsFor -> ready

      runs ->
        expect(someIntegerSpy).toHaveBeenCalled()
        expect(TestApp.get('someInteger')).toEqual(5)

    it 'sends updates back to firebase', ->
      TestApp.set('someInteger', 19)
      childRef = TestApp.firebase.child("syncs/someInteger")
      ready = false
      firebaseValue = null

      runs ->
        childRef.once 'value', (snapshot) ->
          firebaseValue = snapshot.val()
          ready = true

      waitsFor -> ready

      runs ->
        expect(firebaseValue).toEqual(19)

  describe 'JSON serializable', ->
    it 'responds to changes from outside', ->
      TestApp.set('someObject', {name: "Fido", type: "dog"})
      someIntegerSpy = jasmine.createSpy()
      TestApp.observe 'someObject.name', ->
        someIntegerSpy()

      childRef = TestApp.firebase.child("syncs/someObject/name")
      ready = false

      runs ->
        childRef.set("Barky", -> ready = true)

      waitsFor -> ready

      runs ->
        expect(someIntegerSpy).toHaveBeenCalled()
        expect(TestApp.get('someObject.name')).toEqual('Barky')

    it 'sends updates back to firebase', ->
      TestApp.set('someObject', {name: "Mittens", type: 'cat'})
      childRef = TestApp.firebase.child("syncs/someObject")
      ready = false
      firebaseValue = null

      runs ->
        childRef.once 'value', (snapshot) ->
          firebaseValue = snapshot.val()
          ready = true

      waitsFor -> ready

      runs ->
        expect(firebaseValue).toEqual({name: "Mittens", type: 'cat'})

  describe 'maintaining type', ->
    it 'responds to changes from outside', ->
      TestApp.set('someTestModel', new TestApp.TestModel({name: "Cake", type: "dessert"}))
      someBatmanObjectSpy = jasmine.createSpy()
      TestApp.observe 'someTestModel.name', ->
        someBatmanObjectSpy()

      childRef = TestApp.firebase.child("syncs/someTestModel/name")
      childRef.set("Pie")
      ready = false
      runs ->
        setTimeout ->
            ready = true
          , 50 # let firebase catch up

      waitsFor -> ready

      runs ->
        expect(someBatmanObjectSpy).toHaveBeenCalled()
        expect(TestApp.get('someTestModel').constructor.resourceName).toEqual('test_model')
        expect(TestApp.get('someTestModel.name')).toEqual('Pie')

    it 'sends updates back to firebase', ->
      TestApp.set('someTestModel', new TestApp.TestModel({name: "Mittens", type: 'cat'}))
      TestApp.set('someTestModel.name', 'Meowy')
      childRef = TestApp.firebase.child("syncs/someTestModel")
      ready = false
      firebaseValue = null

      runs ->
        childRef.once 'value', (snapshot) ->
          firebaseValue = snapshot.val()
          ready = true

      waitsFor -> ready

      runs ->
        expect(TestApp.get('someTestModel').toJSON()).toEqual({name: "Meowy", type: 'cat'})
        expect(firebaseValue).toEqual({name: "Meowy", type: 'cat'})
