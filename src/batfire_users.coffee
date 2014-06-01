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
      Batman._scopedModels ?= []
      model.clear() for model in Batman._scopedModels
      @_updateCurrentUser({})

    @classAccessor 'loggedIn', ->  !!@get('currentUser.uid')
    @classAccessor 'loggedOut', -> !@get('loggedIn')

Batman.App.classMixin(BatFire.AuthAppMixin)


class BatFire.CurrentUserValidator extends Batman.Validator
  @triggers 'ownedByCurrentUser'

  validateEach: (errors, record, key, callback) ->
    if !record.get('isNew') # these are only set after create
      if !record.get('hasOwner')
        errors.add('base', "This record doesn't have an owner!")
      else if !record.get('isOwnedByCurrentUser')
        errors.add('base', "You don't own this record!")
    else
      if !Batman.currentApp.get('currentUser')?
        errors.add('base', "You must be logged in to create this!")
    callback()

Batman.Validators.push(BatFire.CurrentUserValidator)

BatFire.AuthModelMixin =
  CREATED_BY_FIELDS: ['uid', 'email', 'username']

  initialize: ->
    @belongsToCurrentUser = ({scoped, ownership}={})->
      for attr in BatFire.AuthModelMixin.CREATED_BY_FIELDS
        do (attr) =>
          accessorName = "created_by_#{attr}"
          @accessor(accessorName, Batman.Model.defaultAccessor) # uses default accessor
          @encode(accessorName)

      @accessor 'hasOwner', -> @get('created_by_uid')?
      @accessor 'isOwnedByCurrentUser', ->
        @get('hasOwner') and @get('created_by_uid') is Batman.currentApp.get('currentUser.uid')

      # used by the storage adapter:
      @set('_belongsToCurrentUser', true)
      @accessor('_belongsToCurrentUser', -> true)

      if ownership
        @validate('created_by_uid',{ownedByCurrentUser: true})
        @set('hasUserOwnership', true) # picked up in the storage adapter
        @accessor 'hasUserOwnership', -> true # picked up in the storage adapter
        @encode('hasUserOwnership', as: 'has_user_ownership')

      if scoped
        Batman._scopedModels ?= []
        Batman._scopedModels.push(@)
        @set('isScopedToCurrentUser', true) # picked up by storage adapter
        @accessor 'isScopedToCurrentUser', -> @constructor.get('isScopedToCurrentUser')



Batman.Model.classMixin(BatFire.AuthModelMixin)
