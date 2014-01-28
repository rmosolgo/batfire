# Batman.Firebase

Batman.Firebase is a [batman.js](http://batmanjs.org/) [`StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) for [Firebase](https://www.firebase.com/). It's available in [CoffeeScript](https://github.com/rmosolgo/batman-firebase/tree/master/src/batman.firebase.coffee), [JavaScript](https://github.com/rmosolgo/batman-firebase/tree/master/dist/batman.firebase.js) or [minified JavaScript](https://github.com/rmosolgo/batman-firebase/tree/master/dist/batman.firebase.js).

It ain't done yet, but it works. See `to do` or the specs.

# Usage


### 1. Load the files

  In the asset pipeline:

  ```coffeescript
  #= require batman
  #= require batman.firebase
  ```

  Or in your HTML:

  ```html
  <script src='/lib/batman.js'></script>
  <script src='/lib/batman.firebase.js'></script>
  ```

### 2. `YourApp.syncsWithFirebase("your-app")`

  For example,

  ```coffeescript
  class App extends Batman.App
    @syncsWithFirebase "my-firebase-app-name"
  ```

  will sync with `https://my-firebase-app-name.firebaseio.com`

### 3. `@persist` your models with `Batman.Firebase.Storage`

  ```
  class App.Sandwich extends Batman.Model
    @resourceName: 'sandwich'
    @persist Batman.Firebase.Storage
    @encode "id", "meats", "tomato", "lettuce"
  ```

### 4. Get to work!

  ```coffeescript
  App.run()

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

- You can listen to _all_ records by calling `Model.load()`. This sets up handlers for `child_added`, `child_removed`, and `child_changed`. Calling `Model.clear()` empties the loaded set and stops listening.
- `Model.load` doesn't return all records! Firebase just doesn't work like that. It does set up a Firebase listener to populate the `loaded` set, though.

# To do

- `read` and friends should listen for value events?
- Allow custom function for generating IDs


__License:__ [MIT](http://opensource.org/licenses/MIT)
