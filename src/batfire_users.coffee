class BatFire.User extends Batman.Object

BatFire.AppUserMixin =
  initialize: ->
    @authorizesWithFirebase = (@defaultProviderString=null) ->
      @set 'currentUser', new BatFire.User
      @on 'run', =>
        @set 'auth', new FirebaseSimpleLogin @get('firebase.ref'), (err, user) =>
          if err?
            throw err
          else
            @_updateCurrentUser(user)

    @_updateCurrentUser = (attrs) ->
      @get('currentUser').mixin(attrs)

    @login = (provider=null, options={}) ->
      provider ?= @defaultProviderString
      @get('auth').login(provider, options)

    @logout = ->
      @get('auth').logout()
      @_updateCurrentUser({})

Batman.App.classMixin(BatFire.AppUserMixin)
