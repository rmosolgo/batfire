class BatFire.User extends Batman.Object

BatFire.AuthAppMixin =
  initialize: ->
    @authorizesWithFirebase = (@providers...) ->
      @set 'currentUser', new BatFire.User
      @on 'run', =>
        @set 'auth', new FirebaseSimpleLogin @get('firebase.ref'), (err, user) =>
          if err?
            throw err
          else
            @_updateCurrentUser(user)

    @_updateCurrentUser = (attrs={}) ->
      @set("currentUser", new BatFire.User(attrs))

    @login = (provider, options={}) ->
      if @providers.length is 1
        provider ?= @providers[0]
      if (@providers.length) and (provider not in @providers)
        throw "Auth provider #{provider} not in whitelisted providers [#{@providers.join(", ")}]"

      @get('auth').login(provider, options)

    @logout = ->
      @get('auth').logout()
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', ->  !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('loggedIn')

Batman.App.classMixin(BatFire.AuthAppMixin)

BatFire.AuthModelMixin =
  initialize: ->
    @belongsToCurrentUser = ({})->
      for attr in ['uid', 'email', 'username']
        do (attr) =>
          accessorName = "created_by_#{attr}"
          @accessor accessorName , -> Batman.currentApp.get("currentUser.#{attr}")
          @encode accessorName

Batman.Model.classMixin(BatFire.AuthModelMixin)
