class BatFire.User extends Batman.Object

BatFire.AppUserMixin =
  initialize: ->
    @authorizesWithFirebase = (@providers...) ->
      @set 'currentUser', new BatFire.User
      @on 'run', =>
        @set 'auth', new FirebaseSimpleLogin @get('firebase.ref'), (err, user) =>
          if err?
            throw err
          else
            @_updateCurrentUser(user)

    @_updateCurrentUser = (attrs) ->
      @get('currentUser')?.mixin(attrs)

    @login = (provider, options={}) ->
      if @providers.length is 1
        provider ?= @providers[0]
      if (@providers.length) and (provider not in @providers)
        throw "Auth provider #{provider} not in whitelisted providers [#{@providers.join(", ")}]"

      @get('auth').login(provider, options)

    @logout = ->
      @get('auth').logout()
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', -> !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('currentUser.uid')

Batman.App.classMixin(BatFire.AppUserMixin)
