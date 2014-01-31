describe 'App.syncsAccessor', ->
  describe 'simple values', ->
    it 'responds to changes from outside', ->
      TestApp.set('someInteger', 3)
      someIntegerSpy = jasmine.createSpy()
      TestApp.observe 'someInteger', ->
        someIntegerSpy()

      childRef = TestApp.firebase.child("BatFire/someInteger")
      childRef.set(5)
      ready = false
      runs ->
        setTimeout ->
            ready = true
          , 50 # let firebase catch up

      waitsFor -> ready

      runs ->
        expect(someIntegerSpy).toHaveBeenCalled()
        expect(TestApp.get('someInteger')).toEqual(5)

    it 'sends updates back to firebase', ->
      TestApp.set('someInteger', 19)
      childRef = TestApp.firebase.child("BatFire/someInteger")
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

      childRef = TestApp.firebase.child("BatFire/someObject/name")
      childRef.set("Barky")
      ready = false
      runs ->
        setTimeout ->
            ready = true
          , 50 # let firebase catch up

      waitsFor -> ready

      runs ->
        expect(someIntegerSpy).toHaveBeenCalled()
        expect(TestApp.get('someObject.name')).toEqual('Barky')

    it 'sends updates back to firebase', ->
      TestApp.set('someObject', {name: "Mittens", type: 'cat'})
      childRef = TestApp.firebase.child("BatFire/someObject")
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
      TestApp.set('someBatmanObject', new Batman.Object({name: "Cake", type: "dessert"}))
      someBatmanObjectSpy = jasmine.createSpy()
      TestApp.observe 'someBatmanObject.name', ->
        someBatmanObjectSpy()

      childRef = TestApp.firebase.child("BatFire/someBatmanObject/name")
      childRef.set("Pie")
      ready = false
      runs ->
        setTimeout ->
            ready = true
          , 50 # let firebase catch up

      waitsFor -> ready

      runs ->
        expect(someBatmanObjectSpy).toHaveBeenCalled()
        expect(TestApp.get('someBatmanObject').constructor).toEqual((new Batman.Object).constructor)
        expect(TestApp.get('someBatmanObject.name')).toEqual('Pie')

    it 'sends updates back to firebase', ->
      TestApp.set('someBatmanObject', new Batman.Object({name: "Mittens", type: 'cat'}))
      TestApp.set('someBatmanObject.name', 'Meowy')
      childRef = TestApp.firebase.child("BatFire/someBatmanObject")
      ready = false
      firebaseValue = null

      runs ->
        childRef.once 'value', (snapshot) ->
          firebaseValue = snapshot.val()
          ready = true

      waitsFor -> ready

      runs ->
        expect(firebaseValue).toEqual({name: "Meowy", type: 'cat'})
