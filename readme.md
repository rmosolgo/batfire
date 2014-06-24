# BatFire

BatFire is a [Firebase](https://www.firebase.com/) client library for [batman.js](http://batmanjs.org/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js), and [minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js). BatFire offers:

- A storage adapter, [`BatFire.Storage`](#batfirestorage), for saving your records and updating clients in real time
- App-wide, real-time-syncing accessors with [`@syncs`](#appsyncs)
- A simple [wrapper around Firebase authentication](#authorization)
- Client-side pseudo-access control with [`Model.belongsToCurrentUser`](#modelbelongstocurrentuser)

Also see [example security rules](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json), the [Jasmine spec suite](https://github.com/rmosolgo/batfire/tree/master/spec) or an [example app](http://github.com/rmosolgo/batmanjs-blog).

# Usage

- __Get the files:__

  Install with Bower:

  ```
  bower install batfire
  ```

  Or, download BatFire in a form of your choice: [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js), [Minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js)

- __Load the files:__

  Be sure to include BatFire _after_ you include Firebase and batman.js. For example:

  ```html
  <script src='/path/to/firebase.js'></script>
  <script src='/path/to/batman.js'></script>
  <script src='/path/to/batfire.js'></script>
  ```

- __`@syncsWithFirebase("your-app")`__

  For example,

  ```coffeescript
  class MyApp extends Batman.App
    @syncsWithFirebase "my-firebase-app-name"
  ```

  will sync with `https://my-firebase-app-name.firebaseio.com`.

# BatFire.Storage

`BatFire.Storage` implements the [`Batman.StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) interface, so you can pass it to `@persist` in your model definition. ([Learn more about BatFire.Storage](https://github.com/rmosolgo/batfire/blob/master/doc/model.md#batmanmodel))


For example:

```coffeescript
class App.Sandwich extends Batman.Model
  @resourceName: 'sandwich'
  @persist BatFire.Storage
  @encode "meats", "tomato", "lettuce"
  @encodesTimestamps()
```

Now, all the storage operations of your records will trigger updates on Firebase:

```coffeescript
blt = new App.Sandwich(meats: ["bacon"], lettuce: true, tomato: true)
blt.save()    # => BLT will appear for all clients!
blt.get('id') # => "-JELsmNtuZ4FX6D5f_Ou" and the like
blt.destroy() # => BLT will be gone from all clients!

App.Sandwich.find "-JELsxaWRqaDlDZJHw3y", (err, record) ->
  record.get('name') # => 'Reuben'
```

Items added, removed, and changed on Firebase will be propagated to all connected `loaded` sets.

```coffeescript
App.Sandwich.get('all') # => starts listening for new sandwiches on Firebase, adds them to `Sandwich.loaded`
App.Sandwich.clear() # => clears the loaded set, stops listening for new sandwiches
```

# Authorization

BatFire provides a lightweight wrapper around [FirebaseSimpleLogin](https://www.firebase.com/docs/security/simple-login-overview.html). ([Learn more about authorization](https://github.com/rmosolgo/batfire/blob/master/doc/app.md#authorization))

You define providers in your app definition:

```coffeescript
class App extends Batman.App
  @syncsWithFirebase('my-app-name')
  @authorizesWithFirebase('github', 'facebook')
```

There are also view helpers:

```html
<div data-showif='loggedIn'>
  <span data-bind='currentUser.username | prepend "Welcome, " | append "!"'></span>
  <button data-event-click='logout'>Log out</button>
</div>
<div data-showif='loggedOut'>
  <button data-event-click='login | withArguments "github"'>Log in</button>
</div>
```

# Model.belongsToCurrentUser

If your app `syncsWithFirebase` and `authorizesWithFirebase`, you can get some out-of-the-box features on your models, too. ([Learn more about belongsToCurrentUser](https://github.com/rmosolgo/batfire/blob/master/doc/model.md#belongstocurrentuseroptions))

Call this inside a model definition:

```coffeescript
class App.Sandwich extends Batman.Model
  @belongsToCurrentUser(scoped: true, ownership: true)
```

```coffeescript
yourSandwich.get('hasOwner')              # => true
yourSandwich.get('isOwnedByCurrentUser')  # => false
yourSandwich.get('created_by_uid')        # => "github:123456"
```

# App.syncs

`App.syncs` binds keypaths on your app to Firebase so that if they're updated on client, the updates are pushed to the others:

```coffeescript
class App extends Batman.App
         # key...            # optional: constructor name for loading from Firebase, relative to App
  @syncs 'sandwichOfTheDay', as: "Sandwich"
```

([Learn more about App.syncs](https://github.com/rmosolgo/batfire/blob/master/doc/app.md#syncsattrname-options))

# To do

- Allow custom function for generating IDs
- shorthand `App.syncsWithFirebase(key, {authorizes: authArguments})`

# Development

- `npm install`
- tests: `npm run-script spec`
- build: `npm run-script build`


__License:__ [MIT](http://opensource.org/licenses/MIT)

