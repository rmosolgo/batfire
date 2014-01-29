# BatFire

BatFire is a [batman.js](http://batmanjs.org/) [`StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) for [Firebase](https://www.firebase.com/). It's available in [CoffeeScript](https://raw.github.com/rmosolgo/batman-firebase/master/src/batman.firebase.coffee), [JavaScript](https://raw.github.com/rmosolgo/batman-firebase/master/batman.firebase.js) or [minified JavaScript](https://raw.github.com/rmosolgo/batman-firebase/master/batman.firebase.min.js).

It ain't done yet, but it works. See `to do` or the specs.

# Usage


### 1. Load the files

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

### 2. `YourApp.syncsWithFirebase("your-app")`

  For example,

  ```coffeescript
  class App extends Batman.App
    @syncsWithFirebase "my-firebase-app-name"
  ```

  will sync with `https://my-firebase-app-name.firebaseio.com`

### 3. `@persist` your models with `BatFire.Storage`

  ```
  class App.Sandwich extends Batman.Model
    @resourceName: 'sandwich'
    @persist BatFire.Storage
    @encode "meats", "tomato", "lettuce" # @primaryKey will be encoded automatically
  ```

### 4. Get to work!

  ```coffeescript
  App.run() # make sure you call run!

  blt = new App.Sandwich(meats: ["Bacon"], lettuce: true, tomato: true)
  blt.save()
  blt.get('id') # => "-JELsmNtuZ4FX6D5f_Ou" and the like
  blt.destroy()

  App.Sandwich.find "-JELsxaWRqaDlDZJHw3y", (err, record) ->
    record.get('name') # => 'Reuben'

  App.Sandwich.get('all') # => starts listening for new sandwiches on Firebase, adds them to `Sandwich.loaded`
  App.Sandwich.clear() # => clears the loaded set, stops listening for new sandwiches
  ```

Items added, removed, and changed on Firebase will be propagated to all connected `loaded` sets.

# Notes

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

