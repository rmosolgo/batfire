// Generated by CoffeeScript 1.6.3
(function() {
  var _ref, _ref1,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  this.BatFire = (function() {
    function BatFire() {}

    BatFire.VERSION = '0.0.1';

    return BatFire;

  })();

  BatFire.Reference = (function() {
    function Reference(_arg) {
      this.path = _arg.path, this.parent = _arg.parent;
      if (this.parent) {
        this.ref = this.parent.child(this.path);
      } else {
        this.ref = new Firebase(this.path);
      }
    }

    Reference.prototype.child = function(path) {
      return this.ref.child(path);
    };

    return Reference;

  })();

  BatFire.AppMixin = {
    initialize: function() {
      var appSet;
      this.syncsWithFirebase = function(firebaseAppName) {
        this.firebaseAppName = firebaseAppName;
        this.firebaseURL = "https://" + this.firebaseAppName + ".firebaseio.com/";
        return this.set('firebase', new BatFire.Reference({
          path: this.firebaseURL
        }));
      };
      this.syncs = function(keypathString, _arg) {
        var as, childRef, firebasePath, syncConstructor,
          _this = this;
        as = (_arg != null ? _arg : {}).as;
        if (this._syncKeypaths == null) {
          this._syncKeypaths = [];
        }
        this._syncKeypaths.push(keypathString);
        firebasePath = keypathString.replace(/\./, '/');
        childRef = this.get('firebase').child("BatFire/" + firebasePath);
        syncConstructor = as;
        this.observe(keypathString, function(newValue, oldValue) {
          if (newValue === oldValue || Batman.typeOf(newValue) === 'Undefined') {
            return;
          }
          if (newValue != null ? newValue.toJSON : void 0) {
            newValue = newValue.toJSON();
          }
          return childRef.set(newValue);
        });
        return childRef.on('value', function(snapshot) {
          var value;
          value = snapshot.val();
          if (syncConstructor != null) {
            value = new syncConstructor(value);
          }
          return _this.set(keypathString, value);
        });
      };
      this._updateFirebaseChild = function(keypathString, newValue) {
        var childRef, firebasePath;
        firebasePath = keypathString.replace(/\./, '/');
        childRef = this.get('firebase').child("BatFire/" + firebasePath);
        if (newValue != null ? newValue.toJSON : void 0) {
          newValue = newValue.toJSON();
        }
        return childRef.set(newValue);
      };
      appSet = this.set;
      return this.set = function() {
        var firstKeypathPart, keypathString, value;
        keypathString = arguments[0];
        value = arguments[1];
        firstKeypathPart = keypathString.split(".")[0];
        if (__indexOf.call(this._syncKeypaths || [], firstKeypathPart) >= 0) {
          this._updateFirebaseChild(keypathString, value);
        }
        return appSet.apply(this, arguments);
      };
    }
  };

  Batman.App.classMixin(BatFire.AppMixin);

  BatFire.Storage = (function(_super) {
    __extends(Storage, _super);

    function Storage() {
      var _BatFireClearLoaded,
        _this = this;
      Storage.__super__.constructor.apply(this, arguments);
      this.firebaseClass = Batman.helpers.pluralize(this.model.resourceName);
      this.model.encode(this.model.get('primaryKey'));
      _BatFireClearLoaded = this.model.clear;
      this.model.clear = function() {
        var result;
        result = _BatFireClearLoaded.apply(_this.model);
        _this.model.unset('ref');
        return result;
      };
    }

    Storage.prototype._createRef = function() {
      return Batman.currentApp.get('firebase').child(this.firebaseClass);
    };

    Storage.prototype._listenToList = function() {
      var ref,
        _this = this;
      if (!this.model.get('ref')) {
        ref = this._createRef();
        ref.on('child_added', function(snapshot) {
          var record;
          return record = _this.model.createFromJSON(snapshot.val());
        });
        ref.on('child_removed', function(snapshot) {
          var record;
          record = _this.model.createFromJSON(snapshot.val());
          return _this.model.get('loaded').remove(record);
        });
        ref.on('child_changed', function(snapshot) {
          var record;
          return record = _this.model.createFromJSON(snapshot.val());
        });
        return this.model.set('ref', ref);
      }
    };

    Storage.prototype.before('create', 'update', 'read', 'destroy', 'readAll', 'destroyAll', Storage.skipIfError(function(env, next) {
      var ref;
      env.primaryKey = this.model.primaryKey;
      ref = this.model.get('ref') || this._createRef();
      if (env.subject.get(env.primaryKey) != null) {
        env.firebaseRef = ref.child(env.subject.get(env.primaryKey));
      } else if (env.action === 'readAll' || env.action === 'destroyAll') {
        env.firebaseRef = ref;
      } else {
        env.firebaseRef = ref.push();
      }
      return next();
    }));

    Storage.prototype.after('create', 'update', 'read', 'destroy', Storage.skipIfError(function(env, next) {
      env.result = env.subject;
      return next();
    }));

    Storage.prototype.after('readAll', Storage.skipIfError(function(env, next) {
      env.result = [];
      return next();
    }));

    Storage.prototype.create = Storage.skipIfError(function(env, next) {
      var firebaseId;
      firebaseId = env.firebaseRef.name();
      env.subject._withoutDirtyTracking(function() {
        return this.set(env.primaryKey, firebaseId);
      });
      return env.firebaseRef.set(env.subject.toJSON(), function(err) {
        if (err) {
          env.error = err;
          console.log(err);
        }
        return next();
      });
    });

    Storage.prototype.read = Storage.skipIfError(function(env, next) {
      var _this = this;
      return env.firebaseRef.once('value', function(snapshot) {
        var data;
        data = snapshot.val();
        if (data == null) {
          env.error = new _this.constructor.NotFoundError;
        } else {
          env.subject._withoutDirtyTracking(function() {
            return this.fromJSON(data);
          });
        }
        return next();
      });
    });

    Storage.prototype.update = Storage.skipIfError(function(env, next) {
      return env.firebaseRef.set(env.subject.toJSON(), function(err) {
        if (err) {
          env.error = err;
          console.log(err);
        }
        return next();
      });
    });

    Storage.prototype.destroy = Storage.skipIfError(function(env, next) {
      return env.firebaseRef.remove(function(err) {
        if (err) {
          env.error = err;
        }
        return next();
      });
    });

    Storage.prototype.readAll = Storage.skipIfError(function(env, next) {
      this._listenToList();
      return next();
    });

    Storage.prototype.destroyAll = Storage.skipIfError(function(env, next) {
      return env.firebaseRef.remove(function(err) {
        if (err) {
          env.error = err;
        }
        return next();
      });
    });

    return Storage;

  })(Batman.StorageAdapter);

  BatFire.User = (function(_super) {
    __extends(User, _super);

    function User() {
      _ref = User.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return User;

  })(Batman.Object);

  BatFire.AuthAppMixin = {
    initialize: function() {
      this.authorizesWithFirebase = function() {
        var providers,
          _this = this;
        providers = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.providers = providers;
        this.set('currentUser', new BatFire.User);
        return this.on('run', function() {
          return _this.set('auth', new FirebaseSimpleLogin(_this.get('firebase.ref'), function(err, user) {
            if (err != null) {
              throw err;
            } else {
              return _this._updateCurrentUser(user);
            }
          }));
        });
      };
      this._updateCurrentUser = function(attrs) {
        if (attrs == null) {
          attrs = {};
        }
        return this.set("currentUser", new BatFire.User(attrs));
      };
      this.login = function(provider, options) {
        if (options == null) {
          options = {};
        }
        if (this.providers.length === 1) {
          if (provider == null) {
            provider = this.providers[0];
          }
        }
        if (this.providers.length && (__indexOf.call(this.providers, provider) < 0)) {
          throw "Auth provider " + provider + " not in whitelisted providers [" + (this.providers.join(", ")) + "]";
        }
        return this.get('auth').login(provider, options);
      };
      this.logout = function() {
        this.get('auth').logout();
        return this._updateCurrentUser({});
      };
      this.classAccessor('loggedIn', function() {
        return !!this.get('currentUser.uid');
      });
      return this.classAccessor('loggedOut', function() {
        return !this.get('loggedIn');
      });
    }
  };

  Batman.App.classMixin(BatFire.AuthAppMixin);

  BatFire.CurrentUserValidator = (function(_super) {
    __extends(CurrentUserValidator, _super);

    function CurrentUserValidator() {
      _ref1 = CurrentUserValidator.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    CurrentUserValidator.triggers('ownedByCurrentUser');

    CurrentUserValidator.prototype.validateEach = function(errors, record, key, callback) {
      if (!record.isNew()) {
        if (!record.get('hasOwner')) {
          errors.add('created_by_uid', "This record doesn't have an owner!");
        } else if (!record.get('ownedByCurrentUser')) {
          errors.add('created_by_uid', "You don't own this record!");
        }
      }
      return callback();
    };

    return CurrentUserValidator;

  })(Batman.Validator);

  Batman.Validators.push(BatFire.CurrentUserValidator);

  BatFire.AuthModelMixin = {
    initialize: function() {
      this.belongsToCurrentUser = function(_arg) {
        var attr, ownership, scopes, _fn, _i, _len, _ref2, _ref3,
          _this = this;
        _ref2 = _arg != null ? _arg : {}, scopes = _ref2.scopes, ownership = _ref2.ownership;
        _ref3 = ['uid', 'email', 'username'];
        _fn = function(attr) {
          var accessorName;
          accessorName = "created_by_" + attr;
          _this.accessor(accessorName, {
            get: function() {
              var _base;
              if (this._currentUserAttrs == null) {
                this._currentUserAttrs = {};
              }
              return (_base = this._currentUserAttrs)[attr] != null ? (_base = this._currentUserAttrs)[attr] : _base[attr] = Batman.currentApp.get("currentUser." + attr);
            },
            set: function(key, value) {
              if (this._currentUserAttrs == null) {
                this._currentUserAttrs = {};
              }
              return this._currentUserAttrs[attr] = value;
            }
          });
          return _this.encode(accessorName);
        };
        for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
          attr = _ref3[_i];
          _fn(attr);
        }
        if (ownership) {
          return this.validate('created_by_uid', {
            ownedByCurrentUser: true
          });
        }
      };
      this.accessor('hasOwner', function() {
        return this.get('created_by_uid') != null;
      });
      return this.accessor('ownedByCurrentUser', function() {
        return this.get('created_by_uid') && this.get('created_by_uid') === Batman.currentApp.get('currentUser.uid');
      });
    }
  };

  Batman.Model.classMixin(BatFire.AuthModelMixin);

}).call(this);
