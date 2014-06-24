# Batman.Model

`BatFire.Storage` implements the [`Batman.StorageAdapter`](http://batmanjs.org/docs/api/batman.storageadapter.html) interface, so you can pass it to `@persist` in your model definition. For example:

```coffeescript
class App.Sandwich extends Batman.Model
  @resourceName: 'sandwich'
  @persist BatFire.Storage
  @encode "meats", "tomato", "lettuce", "price"
  @belongsToCurrentUser(ownership: true)
  @encodesTimestamps()
  @prioritizedBy('price') # allows sorting & pagination by price
```

- `Model.load()` or `Model.get('all')` set up listeners so that any new data will be added
- `Model.clear()` clears the loaded set and kills the listeners.

## Model Definition

### `@encodesTimestamps()`

Encodes `created_at` and `updated_at` on each record.

### `@prioritizedBy(attrName)`

Records will be saved with [priority](https://www.firebase.com/docs/ordered-data.html) of `@get(attrName)`. This allows pagination & querying.

### `@belongsToCurrentUser(options={})`

When you use this in a model definition, BatFire will:

- save the current user's `email`, `uid`, `username` on new records as `created_by_#{attr}`
- add `ownedByCurrentUser` and `hasOwner` accessors to records

The __`ownership: true`__ option:

- Provides client-side validation on records when being updated or destroyed so that non-creator users can't modify or destroy them.
- This should be complemented by Security Rules ([example](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)).
- Encodes `has_user_ownership=true`, which you can use in your security rules.

The __`scoped: true`__ option:

- Makes records visible only to the users who created them. Behind the scenes, their Firebase URLs are namespaced by `BatFire/records/scoped/$uid`. This way, calling `Model.load` will only load ones that match `currentUser.uid`.
- Use a Security Rule (like [these](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)) to make records read-protected!
- When a user signs out, the loaded set is cleared.

## Class Methods

### `Model.query(queryObj={}, callback)`

If you're using `@prioritizedBy(attrName)`, you can [query your data](https://www.firebase.com/docs/queries.html).

`queryObj` may have `endAt`, `startAt` and `limit` options.

`callback` is fired with `(err, records)`.

### `Model.get('firebasePath')`

Returns the firebase URL for the class.

### `Model.get('ref')`

Returns the underlying Firebase ref for the class

### `Model.destroyAll(callback)`

Destroys all instances of the class. Use with care! Use [security rules](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)!

## Instance Methods

### `record.get('firebasePath')`

Returns the firebase URL for the instance.