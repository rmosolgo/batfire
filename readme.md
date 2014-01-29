# BatFire

BatFire is a [Firebase](https://www.firebase.com/) client library for [batman.js](http://batmanjs.org/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batfire/master/src/batfire.coffee), [JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.js) or [minified JavaScript](https://raw.github.com/rmosolgo/batfire/master/batfire.min.js).

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


# To do

- Allow custom function for generating IDs
- Use StorageAdapter ModelMixin for modifying `clear`, `load`, encoding Primary Key
- add `Model.encodesTimestamps` for updatedAt and createdAt and implement it on the storage adapter
- spec model additions

# Development

- tests: `npm run-script spec`
- build: `npm run-script build`


__License:__ [MIT](http://opensource.org/licenses/MIT)

