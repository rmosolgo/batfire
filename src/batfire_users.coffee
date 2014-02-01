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


class BatFire.CurrentUserValidator extends Batman.Validator
  @triggers 'ownedByCurrentUser'

  validateEach: (errors, record, key, callback) ->
    if !record.isNew() # only validates existing records
      if !record.get('hasOwner')
        errors.add('created_by_uid', "This record doesn't have an owner!")
      else if !record.get('isOwnedByCurrentUser')
        errors.add('created_by_uid', "You don't own this record!")
    callback()

Batman.Validators.push(BatFire.CurrentUserValidator)

BatFire.AuthModelMixin =
  initialize: ->
    @belongsToCurrentUser = ({scoped, ownership}={})->
      for attr in ['uid', 'email', 'username']
        do (attr) =>
          accessorName = "created_by_#{attr}"
          @accessor accessorName,
            get: ->
              @_currentUserAttrs ?= {}
              @_currentUserAttrs[attr] ?= Batman.currentApp.get("currentUser.#{attr}")
            set: (key, value) ->
              @_currentUserAttrs ?= {}
              @_currentUserAttrs[attr] = value
          @accessor Batman.helpers.camelize(accessorName), -> @get(accessorName)
          @encode accessorName

      if ownership
        @validate('created_by_uid',{ownedByCurrentUser: true})
        @set('hasUserOwnership', true) # picked up in the storage adapter
        @accessor 'hasUserOwnership', -> @constructor.get('hasUserOwnership', true) # picked up in the storage adapter

      if scoped
        @set('isScopedToCurrentUser') # picked up by storage adapter

      @accessor 'hasOwner', -> @get('created_by_uid')?
      @accessor 'isOwnedByCurrentUser', ->
        @get('created_by_uid') and @get('created_by_uid') is Batman.currentApp.get('currentUser.uid')

Batman.Model.classMixin(BatFire.AuthModelMixin)
