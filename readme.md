# BatFire

BatFire is a [Firebase](https://www.firebase.com/) client library for [batman.js](http://batmanjs.org/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js), and [minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js). BatFire offers:

- A storage adapter, [`BatFire.Storage`](#batfirestorage), for saving your records and updating clients in real time
- App-wide, real-time-syncing accessors with [`@syncs`](#appsyncs)
- A simple [wrapper around Firebase authentication](#appauthorizeswithfirebase)
- Client-side pseudo-access control with [`Model.belongsToCurrentUser`](#modelbelongstocurrentuser)

Also see [example security rules](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json) and the [Jasmine spec suite](https://github.com/rmosolgo/batfire/tree/master/spec).

# Usage

- __Get the files:__

  Download BatFire in a form of your choice:

  - [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/batfire.coffee)
  - [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js)
  - [Minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js)

- __Load the files:__

  Be sure to include BatFire _after_ you include Firebase and batman.js. For example, in the asset pipeline:

  ```coffeescript
  #= require ./path/to/firebase
  #= require ./path/to/batman
  #= require ./path/to/batfire
  ```

  or in your HTML:

  ```html
  <script src='/path/to/firebase.js'></script>
  <script src='/path/to/batman.js'></script>
  <script src='/path/to/batfire.js'></script>
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

# BatFire.Storage

`BatFire.Storage` implements the [`Batman.StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) interface, so you can pass it to `@persist` in your model definition. For example:

```coffeescript
class App.Sandwich extends Batman.Model
  @resourceName: 'sandwich'
  @persist BatFire.Storage
  @encode "meats", "tomato", "lettuce" # @primaryKey will be encoded automatically
  @encodesTimestamps() # added by BatFire.Storage
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

While the model is connected (ie, you didn't call `Model.clear()`), you can access its Firebase reference directly:

```coffeescript
App.Sandwich.get('ref') # => bare metal Firebase!
```

By the way, all model data URLs are prefixed with `BatFire/records`.

__Notes about `BatFire.Storage`:__

- `BatFire.Storage` will automatically set your model to `@encode` its `primaryKey`
- `@encodesTimestamps()` will encode `created_at` and `updated_at` as ISO strings in the model's JSON.
- You can listen to _all_ records by calling `Model.load()`. This sets up handlers for `child_added`, `child_removed`, and `child_changed`. Calling `Model.clear()` empties the loaded set and stops listening.

# App.syncs

`App.syncs` binds keypaths on your app to Firebase so that if they're updated on client, the updates are pushed to the others. To create a syncing accessor on your app, just call `@syncs` and use it like a normal accessor:

```coffeescript
class App extends Batman.App
         # key...            # optional: constructor name for loading from Firebase, relative to App
  @syncs 'sandwichOfTheDay', as: "Sandwich"
App.run()

mySandwich = new App.Sandwich({name: "French Dip", price: "$7.50"})
App.set('sandwichOfTheDay', mySandwich)
App.set('sandwichOfTheDay.price', "$6.50")
# elsewhere...
App.get('sandwichOfTheDay') # => <App.Sandwich, "French Dip">
App.get('sandwichOfTheDay.price') # => "$6.50"
```

Under the hood, all these accessors' Firebase URLs are prefixed with `BatFire/syncs/`.

__This comes with some caveats__:

- If you don't [__secure__ the paths on Firebase](https://www.firebase.com/docs/security/security-rules.html) ([examples](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)], a malevolent user could update these properties via the console and screw everything up!
- Whatever you're syncing will be sent `toJSON` if it has a `toJSON` method, otherwise it will be sent to Firebase as-is.
- You may specify a constructor function name with `as:`. Objects will be sent to Firebase, and when new values come in, the value will be passed to that constructor.
- This doesn't work: `App.get('sandwichOfTheDay').set('price')`. Sorry! Do it all at once: `App.set('sandwichOfTheDay.price', "$6.25")`.


# App.authorizesWithFirebase

BatFire provides a lightweight wrapper around [FirebaseSimpleLogin](https://www.firebase.com/docs/security/simple-login-overview.html). If you want to use it, make sure to

- include the Firebase login client (see [FirebaseSimpleLogin overview](https://www.firebase.com/docs/security/simple-login-overview.html))
- register your app with whatever providers you're using (eg, [github](https://www.firebase.com/docs/security/simple-login-github.html))

Promise me that you won't depend on client-side authentication to protect your data. Use __[Firebase security rules](https://www.firebase.com/docs/security/security-rules.html)__ ([examples](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)! Now, in your App definition:

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

## Provider Whitelist
```coffeescript
class App extends Batman.App
  @authorizesWithFirebase('github', 'twitter')
```

If you pass strings to `authorizesWithFirebase`:

- they will be available at `App.get('providers')`
- `App.login` will throw an error if the passed string isn't on the list

## Default Provider

If you pass one provider string to `authorizesWithFirebase`, it will be used by `App.login`:

```coffeescript
class App extends Batman.App
  # ...
  @authorizesWithFirebase('facebook')
App.run()

App.login() # will use 'facebook'
```

# Model.belongsToCurrentUser

If your app `syncsWithFirebase` and `authorizesWithFirebase`, you can get some out-of-the-box features on your models, too, with `Model.belongsToCurrentUser`. Call this inside a model definition:

```coffeescript
class App.Sandwich extends Batman.Model
  @belongsToCurrentUser scoped: true, ownership: true
```

Calling __`@belongsToCurrentUser`__ causes this model to:
- save the current user's `email`, `uid`, `username` on new records as `created_by_#{attr}`
- add `ownedByCurrentUser` and `hasOwner` accessors to records

The __`ownership: true`__ option:
- provides client-side validation on records when being updated or destroyed so that non-creator users can't modify or destroy them (_this should be complemented by Security Rules_, for [example](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)...).
- encodes `has_user_ownership=true`, which you can use in your security rules.

The __`scoped: true`__ option:
- makes records visible only to the users who created them. Behind the scenes, their Firebase URLs are namespaced by `BatFire/records/scoped/$uid`. This way, calling `Model.load` will only load ones that match `currentUser.uid`. It's not Fort Knox, though. Use a Security Rule (like [these](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)) to make records read-protected!
- when a user signs out, the loaded set is cleared.

# To do

- Allow custom function for generating IDs
- shorthand `App.syncsWithFirebase(key, {authorizes: authArguments})`

# Development

- `npm install`
- tests: `npm run-script spec`
- build: `npm run-script build`


__License:__ [MIT](http://opensource.org/licenses/MIT)

