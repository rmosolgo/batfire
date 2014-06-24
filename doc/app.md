# Batman.App

Topics:

- Firebase Setup
- Authorization

## Firebase Setup

### `@syncsWithFirebase(firebaseName)`

### `@syncs(attrName, options={})`

### `App.get('firebase')`

## Authorization

BatFire provides a lightweight wrapper around [FirebaseSimpleLogin](https://www.firebase.com/docs/security/simple-login-overview.html). If you want to use it, make sure to:

- include the Firebase login client (see [FirebaseSimpleLogin overview](https://www.firebase.com/docs/security/simple-login-overview.html))
- register your app with whatever providers you're using (eg, [github](https://www.firebase.com/docs/security/simple-login-github.html))

Promise me that you won't depend on client-side authentication to protect your data. Use __[Firebase security rules](https://www.firebase.com/docs/security/security-rules.html)__ ([examples](https://github.com/rmosolgo/batfire/blob/master/examples/security_rules.json)!


Now, in your App definition:

```coffeescript
class App extends Batman.App
  @syncsWithFirebase('my-app-name')
  @authorizesWithFirebase('github', 'twitter')
```

### `@authorizesWithFirebase([providers...])`

Initializes all other authentication methods.

If you pass any `providers`, they'll be iterable as `App.get("providers")`.

If you only pass one `provider`, it will be the implicitly passed to `App.login()`

### `App.login([providerString])`

Initiates the login process with that provider (eg, `'github'`). If you only pass one provider to `@authorizesWithFirebase`, it will be used as the default `providerString`.

### `App.logout()`

Logs out the current user.

### `App.get('currentUser')`

A `Batman.Object` wrapper around the currently-signed-in user. Exposes all values that the underlying Firebase auth object provides (see `App.get('auth')`). You can call `App.get('currentUser').toJSON()` to see all the values available for a given provider.

### `App.get('loggedIn')`

Returns true if there's a `currentUser`.

### `App.get('loggedOut')`

Returns true if there's not a `currentUser`.

### `App.get('auth')`

The underlying Firebase auth object.