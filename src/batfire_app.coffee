BatFire.AppMixin =
  initialize: ->
    @syncsWithFirebase = (@firebaseAppName) ->
      @firebaseURL = "https://#{@firebaseAppName}.firebaseio.com/"
      @firebase = new BatFire.Reference(path: @firebaseURL)

    @syncs = (keypathString, {as}={}) ->
      @_syncKeypaths ?= []
      @_syncKeypaths.push(keypathString)
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @firebase.child("BatFire/#{firebasePath}")
      syncConstructor = as
      @observe keypathString, (newValue, oldValue) =>
        return if newValue is oldValue or Batman.typeOf(newValue) is 'Undefined'
        newValue = newValue.toJSON() if newValue?.toJSON
        childRef.set(newValue)
      childRef.on 'value', (snapshot) =>
        value = snapshot.val()
        if syncConstructor?
          value = new syncConstructor(value)
        @set(keypathString, value)

    @_updateFirebaseChild = (keypathString, newValue) ->
      firebasePath = keypathString.replace(/\./, '/')
      childRef = @firebase.child("BatFire/#{firebasePath}")
      newValue = newValue.toJSON() if newValue?.toJSON
      childRef.set(newValue)

    appSet = @set
    @set = ->
      keypathString = arguments[0]
      value = arguments[1]
      firstKeypathPart = keypathString.split(".")[0]
      if firstKeypathPart in(@_syncKeypaths || [])
        @_updateFirebaseChild(keypathString, value)
      appSet.apply(@, arguments)

Batman.App.classMixin(BatFire.AppMixin)
