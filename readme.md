# BatFire

BatFire is a [Firebase](https://www.firebase.com/) client library for [batman.js](http://batmanjs.org/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/src/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js) or [minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js). BatFire offers:

- A storage adapter, [`BatFire.Storage`](#batfirestorage), for saving your records and updating clients in real time
- App-wide, real-time-syncing accessors with [`@syncs`](#appsyncs)


It ain't done yet, but everything described here works. See `to do` or the specs.

# Usage

1. __Load the files:__

  In the asset pipeline:

  ```coffeescript
  #= require batman
  #= require batfire
  ```

  Or in your HTML:

  ```html
  <script src='/lib/batman.js'></script>
  <script src='/lib/batfire.js'></script>
  ```
2. __YourApp `@syncsWithFirebase("your-app")`__

  For example,

  ```coffeescript
  class App extends Batman.App
    @syncsWithFirebase "my-firebase-app-name" # Make sure you call App.run() -- that's when it really connects!
  ```

  will sync with `https://my-firebase-app-name.firebaseio.com`

## BatFire.Storage

`Batfire.Storage` implements the [`Batman.StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) interface, so you can pass it to `@persist` in your model definition. For example:

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

This comes with some __caveats__:

- If you don't __secure__ the paths on Firebase, a malevolent user could update these properties via the console and screw everything up!
- Whatever you're syncing will be sent `toJSON` if it has a `toJSON` method, otherwise it will be sent to Firebase as-is.
- You may specify a constructor function with `as:`. Objects will be sent to Firebase, and when new values come in, the value will be passed to that constructor.
- This doesn't work: `App.get('sandwichOfTheDay').set('price')`. Sorry! Do it all at once: `App.set('sandwichOfTheDay.price', "$6.25")`.


# To do

- Allow custom function for generating IDs
- add `Model.encodesTimestamps` for updatedAt and createdAt and implement it on the storage adapter
- spec model additions
- Wrap Firebase Authorization

# Development

- tests: `npm run-script spec`
- build: `npm run-script build`


__License:__ [MIT](http://opensource.org/licenses/MIT)

