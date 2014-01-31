# BatFire

BatFire is a [Firebase](https://www.firebase.com/) client library for [batman.js](http://batmanjs.org/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js), and [minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js). BatFire offers:

- A storage adapter, [`BatFire.Storage`](#batfirestorage), for saving your records and updating clients in real time
- App-wide, real-time-syncing accessors with [`@syncs`](#appsyncs)
- A simple, helpful [wrapper around Firebase authentication](#appauthorizeswithfirebase)

It ain't done yet, but everything described here works. See `to do` or the specs.

# Usage

- __Get the files:__

  Download BatFire in a form of your choice:

  - [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee)
  - [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js)
  - [Minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js)

- __Load the files:__

  Be sure to include BatFire _after_ you include batman.js. For example, in the asset pipeline:

  ```coffeescript
  #= require batman
  #= require batfire
  ```

  or in your HTML:

  ```html
  <script src='/lib/batman.js'></script>
  <script src='/lib/batfire.js'></script>
  ```

- __YourApp `@syncsWithFirebase("your-app")`__

  For example,

  ```coffeescript
  class App extends Batman.App
    @syncsWithFirebase "my-firebase-app-name"
  ```

  will sync with `https://my-firebase-app-name.firebaseio.com`. Your "raw" Firebase reference is also available to you:

  ```coffeescript
  App.run()
  App.get('firebase.ref') # => your Firebase reference
  ```

## BatFire.Storage

`BatFire.Storage` implements the [`Batman.StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) interface, so you can pass it to `@persist` in your model definition. For example:

```coffeescript
class App.Sandwich extends Batman.Model
  @resourceName: 'sandwich'
  @persist BatFire.Storage
  @encode "meats", "tomato", "lettuce" # @primaryKey will be encoded automatically
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

__Notes about `BatFire.Storage`:__

- `BatFire.Storage` will automatically set your model to `@encode` its `primaryKey`
- You can listen to _all_ records by calling `Model.load()`. This sets up handlers for `child_added`, `child_removed`, and `child_changed`. Calling `Model.clear()` empties the loaded set and stops listening.
- `Model.load` doesn't return all records! Firebase just doesn't work like that. It does set up a Firebase listener to populate the `loaded` set, though.

## App.syncs

`App.syncs` binds keypaths on your app to Firebase so that if they're updated on client, the updates are pushed to the others. To create a syncing accessor on your app, just call `@syncs` and use it like a normal accessor:

```coffeescript
class App extends Batman.App
         # key...            # optional: constructor when loading from Firebase
  @syncs 'sandwichOfTheDay', as: Batman.Object
App.run()

mySandwich = new Batman.Object({name: "French Dip", price: "$7.50"})
App.set('sandwichOfTheDay', mySandwich)
App.set('sandwichOfTheDay.price', "$6.50")
# elsewhere...
App.get('sandwichOfTheDay') # => <Batman.Object, "French Dip">
App.get('sandwichOfTheDay.price') # => "$6.50"
```

__This comes with some caveats__:

- If you don't [__secure__ the paths on Firebase](https://www.firebase.com/docs/security/security-rules.html), a malevolent user could update these properties via the console and screw everything up!
- Whatever you're syncing will be sent `toJSON` if it has a `toJSON` method, otherwise it will be sent to Firebase as-is.
- You may specify a constructor function with `as:`. Objects will be sent to Firebase, and when new values come in, the value will be passed to that constructor.
- This doesn't work: `App.get('sandwichOfTheDay').set('price')`. Sorry! Do it all at once: `App.set('sandwichOfTheDay.price', "$6.25")`.


## App.authorizesWithFirebase

BatFire provides a lightweight wrapper around [FirebaseSimpleLogin](https://www.firebase.com/docs/security/simple-login-overview.html). If you want to use it, make sure to

- include the Firebase login client (see [FirebaseSimpleLogin overview](https://www.firebase.com/docs/security/simple-login-overview.html))
- register your app with whatever providers you're using (eg, [github](https://www.firebase.com/docs/security/simple-login-github.html))

Promise me that you won't depend on client-side authentication to protect your data. Use __[Firebase security rules](https://www.firebase.com/docs/security/security-rules.html)__! Now, in your App definition:

```coffeescript
class App extends Batman.App
  @syncsWithFirebase('my-app-name')
  @authorizesWithFirebase()
```

This adds to `App`:

- `App.login(providerString)` initiates the login process with that provider (eg, `'github'`).
- `App.get('currentUser')` is where all the user information will be. It's a `Batman.Object`, so it's observable.
- `App.get('loggedIn')` and
- `App.get('loggedOut')` say whether `App.currentUser` is present.
- `App.logout()` logs out the current user.
- `App.get('auth')` is the underlying Firebase auth object.

Since these are on App, you can use them in bindings:

```html
<div data-showif='loggedOut'>
  <button data-event-click='login | withArguments "github"'>Log in</button>
</div>
<div data-showif='loggedIn'>
  <span data-bind='currentUser.username | prepend "Welcome, " | append "!"'></span>
  <button data-event-click='logout'>Log out</button>
</div>
```

## Default Provider

If you pass a provider string to `authorizesWithFirebase`, it will be used by `App.login`:

```coffeescript
class App extends Batman.App
  # ...
  @authorizesWithFirebase('facebook')

App.run()

App.login() # will use 'facebook'
```

# To do

- Allow custom function for generating IDs
- add `Model.encodesTimestamps` for updatedAt and createdAt and implement it on the storage adapter
- add `Model.belongsToCurrentUser({scoped, protected})`
- shorthand `App.syncsWithFirebase(key, {authorizes: authArguments})`

# Development

- tests: `npm run-script spec`
- build: `npm run-script build`


__License:__ [MIT](http://opensource.org/licenses/MIT)

