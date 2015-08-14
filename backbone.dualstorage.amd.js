(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['backbone'], factory);
  } else if (typeof require === 'function' && ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null)) {
    return module.exports = factory(require('backbone'));
  } else {
    factory(root.Backbone);
  }
})(this, function(Backbone) {
// Generated by CoffeeScript 1.9.3
(function() {
  var $, LocalStorageAdapter, S4, StickyStorageAdapter, backboneSync, callbackTranslator, dualSync, getStoreName, localSync, modelUpdatedWithResponse, onlineSync, parseRemoteResponse,
    slice = [].slice,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = Backbone.$ || window.$;

  LocalStorageAdapter = (function() {
    function LocalStorageAdapter() {}

    LocalStorageAdapter.prototype.initialize = function() {
      return $.Deferred().resolve().promise();
    };

    LocalStorageAdapter.prototype.setItem = function(key, value) {
      localStorage.setItem(key, value);
      return $.Deferred().resolve(value).promise();
    };

    LocalStorageAdapter.prototype.getItem = function(key) {
      return $.Deferred().resolve(localStorage.getItem(key)).promise();
    };

    LocalStorageAdapter.prototype.removeItem = function(key) {
      localStorage.removeItem(key);
      return $.Deferred().resolve().promise();
    };

    return LocalStorageAdapter;

  })();

  StickyStorageAdapter = (function() {
    function StickyStorageAdapter(name) {
      this.initialize = _.memoize(this.initialize);
      this.name = name || 'Backbone.dualStorage';
    }

    StickyStorageAdapter.prototype.initialize = function() {
      var deferred;
      deferred = $.Deferred();
      this.store = new StickyStore({
        name: this.name,
        adapters: ['indexedDB', 'webSQL', 'localStorage'],
        ready: function() {
          return deferred.resolve();
        }
      });
      return deferred.promise();
    };

    StickyStorageAdapter.prototype.setItem = function(key, value) {
      return this.initialize().then((function(_this) {
        return function() {
          var deferred;
          deferred = $.Deferred();
          _this.store.set(key, value, function(storedValue) {
            return deferred.resolve(storedValue);
          });
          return deferred.promise();
        };
      })(this));
    };

    StickyStorageAdapter.prototype.getItem = function(key) {
      return this.initialize().then((function(_this) {
        return function() {
          var deferred;
          deferred = $.Deferred();
          _this.store.get(key, function(storedValue) {
            return deferred.resolve(storedValue);
          });
          return deferred.promise();
        };
      })(this));
    };

    StickyStorageAdapter.prototype.removeItem = function(key) {
      return this.initialize().then((function(_this) {
        return function() {
          var deferred;
          deferred = $.Deferred();
          _this.store.remove(key, function() {
            return deferred.resolve();
          });
          return deferred.promise();
        };
      })(this));
    };

    return StickyStorageAdapter;

  })();

  Backbone.storageAdapters = {
    LocalStorageAdapter: LocalStorageAdapter,
    StickyStorageAdapter: StickyStorageAdapter
  };


  /*
  Backbone dualStorage Adapter v1.3.1
  
  A simple module to replace `Backbone.sync` with local storage based
  persistence. Models are given GUIDS, and saved into a JSON object. Simple
  as that.
   */

  $ = Backbone.$ || window.$;

  Backbone.storageAdapter = new Backbone.storageAdapters.LocalStorageAdapter;

  Backbone.storageAdapter.initialize();

  Backbone.DualStorage = {
    offlineStatusCodes: [408, 502]
  };

  Backbone.Model.prototype.hasTempId = function() {
    return _.isString(this.id) && this.id.length === 36 && this.id.indexOf('t') === 0;
  };

  getStoreName = function(collection, model) {
    model || (model = collection.model.prototype);
    return _.result(collection, 'storeName') || _.result(model, 'storeName') || _.result(collection, 'url') || _.result(model, 'urlRoot') || _.result(model, 'url');
  };

  Backbone.Collection.prototype.syncDirty = function(options) {
    return Backbone.storageAdapter.getItem((getStoreName(this)) + "_dirty").then((function(_this) {
      return function(store) {
        var id, ids, model, models;
        ids = (store && store.split(',')) || [];
        models = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = ids.length; i < len; i++) {
            id = ids[i];
            results.push(this.get(id));
          }
          return results;
        }).call(_this);
        return $.when.apply($, (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = models.length; i < len; i++) {
            model = models[i];
            if (model) {
              results.push(model.save(null, options));
            }
          }
          return results;
        })());
      };
    })(this));
  };

  Backbone.Collection.prototype.dirtyModels = function(options) {
    return Backbone.storageAdapter.getItem((getStoreName(this)) + "_dirty").then((function(_this) {
      return function(store) {
        var id, ids, models;
        ids = (store && store.split(',')) || [];
        models = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = ids.length; i < len; i++) {
            id = ids[i];
            results.push(this.get(id));
          }
          return results;
        }).call(_this);
        return _.compact(models);
      };
    })(this));
  };

  Backbone.Collection.prototype.syncDestroyed = function(options) {
    return Backbone.storageAdapter.getItem((getStoreName(this)) + "_destroyed").then((function(_this) {
      return function(store) {
        var id, ids, model, models;
        ids = (store && store.split(',')) || [];
        models = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = ids.length; i < len; i++) {
            id = ids[i];
            model = new this.model;
            model.set(model.idAttribute, id);
            model.collection = this;
            results.push(model);
          }
          return results;
        }).call(_this);
        return $.when.apply($, (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = models.length; i < len; i++) {
            model = models[i];
            results.push(model.destroy(options));
          }
          return results;
        })());
      };
    })(this));
  };

  Backbone.Collection.prototype.destroyedModelIds = function() {
    return Backbone.storageAdapter.getItem((getStoreName(this)) + "_destroyed").then((function(_this) {
      return function(store) {
        var ids;
        return ids = (store && store.split(',')) || [];
      };
    })(this));
  };

  Backbone.Collection.prototype.syncDirtyAndDestroyed = function(options) {
    return $.when(this.syncDirty(options), this.syncDestroyed(options));
  };

  S4 = function() {
    return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
  };

  window.Store = (function() {
    Store.prototype.sep = '';

    function Store(name) {
      this.name = name;
      this.dirtyName = name + "_dirty";
      this.destroyedName = name + "_destroyed";
      this.records = [];
    }

    Store.prototype.initialize = function() {
      return this.recordsOn(this.name).done((function(_this) {
        return function(result) {
          return _this.records = result || [];
        };
      })(this));
    };

    Store.prototype.generateId = function() {
      return 't' + S4().substring(1) + S4() + '-' + S4() + '-' + S4() + '-' + S4() + '-' + S4() + S4() + S4();
    };

    Store.prototype.getStorageKey = function(id) {
      if (_.isObject(id)) {
        id = id.id;
      }
      return this.name + this.sep + id;
    };

    Store.prototype.save = function() {
      return Backbone.storageAdapter.setItem(this.name, this.records.join(','));
    };

    Store.prototype.recordsOn = function(key) {
      return Backbone.storageAdapter.getItem(key).then(function(store) {
        return (store && store.split(',')) || [];
      });
    };

    Store.prototype.dirty = function(model) {
      return this.recordsOn(this.dirtyName).then((function(_this) {
        return function(dirtyRecords) {
          if (!_.include(dirtyRecords, model.id.toString())) {
            dirtyRecords.push(model.id.toString());
            return Backbone.storageAdapter.setItem(_this.dirtyName, dirtyRecords.join(',')).then(function() {
              return model;
            });
          }
          return model;
        };
      })(this));
    };

    Store.prototype.clean = function(model, from) {
      var store;
      store = this.name + "_" + from;
      return this.recordsOn(store).then(function(dirtyRecords) {
        if (_.include(dirtyRecords, model.id.toString())) {
          return Backbone.storageAdapter.setItem(store, _.without(dirtyRecords, model.id.toString()).join(',')).then(function() {
            return model;
          });
        }
        return model;
      });
    };

    Store.prototype.destroyed = function(model) {
      return this.recordsOn(this.destroyedName).then((function(_this) {
        return function(destroyedRecords) {
          if (!_.include(destroyedRecords, model.id.toString())) {
            destroyedRecords.push(model.id.toString());
            Backbone.storageAdapter.setItem(_this.destroyedName, destroyedRecords.join(',')).then(function() {
              return model;
            });
          }
          return model;
        };
      })(this));
    };

    Store.prototype.create = function(model) {
      if (!_.isObject(model)) {
        return $.Deferred().resolve(model).promise();
      }
      if (!model.id) {
        model.set(model.idAttribute, this.generateId());
      }
      return Backbone.storageAdapter.setItem(this.getStorageKey(model), JSON.stringify(model)).then((function(_this) {
        return function() {
          _this.records.push(model.id.toString());
          return _this.save().then(function() {
            return model;
          });
        };
      })(this));
    };

    Store.prototype.update = function(model) {
      return Backbone.storageAdapter.setItem(this.getStorageKey(model), JSON.stringify(model)).then((function(_this) {
        return function() {
          if (!_.include(_this.records, model.id.toString())) {
            _this.records.push(model.id.toString());
          }
          return _this.save().then(function() {
            return model;
          });
        };
      })(this));
    };

    Store.prototype.clear = function() {
      var id;
      return $.when.apply($, ((function() {
        var i, len, ref, results;
        ref = this.records;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          id = ref[i];
          results.push(Backbone.storageAdapter.removeItem(this.getStorageKey(id)));
        }
        return results;
      }).call(this))).then((function(_this) {
        return function() {
          _this.records = [];
          return _this.save();
        };
      })(this));
    };

    Store.prototype.hasDirtyOrDestroyed = function() {
      return Backbone.storageAdapter.getItem(this.dirtyName).then((function(_this) {
        return function(dirty) {
          if (!_.isEmpty(dirty)) {
            return true;
          }
          return Backbone.storageAdapter.getItem(_this.destroyedName).then(function(destroyed) {
            return !_.isEmpty(destroyed);
          });
        };
      })(this));
    };

    Store.prototype.find = function(model) {
      return Backbone.storageAdapter.getItem(this.getStorageKey(model)).then(function(modelAsJson) {
        if (modelAsJson === null) {
          return null;
        }
        return JSON.parse(modelAsJson);
      });
    };

    Store.prototype.findAll = function() {
      var id;
      return $.when.apply($, ((function() {
        var i, len, ref, results;
        ref = this.records;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          id = ref[i];
          results.push(Backbone.storageAdapter.getItem(this.getStorageKey(id)));
        }
        return results;
      }).call(this))).then(function() {
        var i, len, model, models, results;
        models = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        results = [];
        for (i = 0, len = models.length; i < len; i++) {
          model = models[i];
          results.push(JSON.parse(model));
        }
        return results;
      });
    };

    Store.prototype.destroy = function(model) {
      return Backbone.storageAdapter.removeItem(this.getStorageKey(model)).then((function(_this) {
        return function() {
          _this.records = _.without(_this.records, model.id.toString());
          return _this.save().then(function() {
            return model;
          });
        };
      })(this));
    };

    Store.exists = function(storeName) {
      return Backbone.storageAdapter.getItem(storeName).then(function(value) {
        return value !== null;
      });
    };

    return Store;

  })();

  callbackTranslator = {
    needsTranslation: Backbone.VERSION === '0.9.10',
    forBackboneCaller: function(callback) {
      if (this.needsTranslation) {
        return function(model, resp, options) {
          return callback.call(null, resp);
        };
      } else {
        return callback;
      }
    },
    forDualstorageCaller: function(callback, model, options) {
      if (this.needsTranslation) {
        return function(resp) {
          return callback.call(null, model, resp, options);
        };
      } else {
        return callback;
      }
    }
  };

  localSync = function(method, model, options) {
    var isValidModel, store;
    isValidModel = (method === 'clear') || (method === 'hasDirtyOrDestroyed');
    isValidModel || (isValidModel = model instanceof Backbone.Model);
    isValidModel || (isValidModel = model instanceof Backbone.Collection);
    if (!isValidModel) {
      throw new Error('model parameter is required to be a backbone model or collection.');
    }
    store = new Store(options.storeName);
    return store.initialize().then(function() {
      var promise;
      promise = (function() {
        switch (method) {
          case 'read':
            if (model instanceof Backbone.Model) {
              return store.find(model);
            } else {
              return store.findAll();
            }
            break;
          case 'hasDirtyOrDestroyed':
            return store.hasDirtyOrDestroyed();
          case 'clear':
            return store.clear();
          case 'create':
            return store.find(model).then(function(preExisting) {
              if (options.add && !options.merge && preExisting) {
                return preExisting;
              } else {
                return store.create(model).then(function(model) {
                  if (options.dirty) {
                    return store.dirty(model).then(function() {
                      return model;
                    });
                  }
                  return model;
                });
              }
            });
          case 'update':
            return store.update(model).then(function(model) {
              if (options.dirty) {
                return store.dirty(model);
              } else {
                return store.clean(model, 'dirty');
              }
            });
          case 'delete':
            return store.destroy(model).then(function() {
              if (options.dirty && !model.hasTempId()) {
                return store.destroyed(model);
              } else {
                if (model.hasTempId()) {
                  return store.clean(model, 'dirty');
                } else {
                  return store.clean(model, 'destroyed');
                }
              }
            });
        }
      })();
      return promise.then(function(response) {
        if (response != null ? response.attributes : void 0) {
          response = response.attributes;
        }
        if (!options.ignoreCallbacks) {
          if (response) {
            options.success(response);
          } else {
            options.error('Record not found');
          }
        }
        return response;
      });
    });
  };

  parseRemoteResponse = function(object, response) {
    if (!(object && object.parseBeforeLocalSave)) {
      return response;
    }
    if (_.isFunction(object.parseBeforeLocalSave)) {
      return object.parseBeforeLocalSave(response);
    }
  };

  modelUpdatedWithResponse = function(model, response) {
    var modelClone;
    modelClone = new Backbone.Model;
    modelClone.idAttribute = model.idAttribute;
    modelClone.set(model.attributes);
    modelClone.set(model.parse(response));
    return modelClone;
  };

  backboneSync = Backbone.sync;

  onlineSync = function(method, model, options) {
    options.success = callbackTranslator.forBackboneCaller(options.success);
    options.error = callbackTranslator.forBackboneCaller(options.error);
    return backboneSync(method, model, options);
  };

  dualSync = function(method, model, options) {
    var error, hasOfflineStatusCode, local, relayErrorCallback, storeExistsPromise, success, temporaryId, useOfflineStorage;
    options.storeName = getStoreName(model.collection, model);
    options.success = callbackTranslator.forDualstorageCaller(options.success, model, options);
    options.error = callbackTranslator.forDualstorageCaller(options.error, model, options);
    if (_.result(model, 'remote') || _.result(model.collection, 'remote')) {
      return onlineSync(method, model, options);
    }
    local = _.result(model, 'local') || _.result(model.collection, 'local');
    options.dirty = options.remote === false && !local;
    if (options.remote === false || local) {
      return localSync(method, model, options);
    }
    options.ignoreCallbacks = true;
    success = options.success;
    error = options.error;
    storeExistsPromise = Store.exists(options.storeName);
    useOfflineStorage = function() {
      options.dirty = true;
      options.ignoreCallbacks = false;
      options.success = success;
      options.error = error;
      return localSync(method, model, options).then(function(result) {
        return success(result);
      });
    };
    hasOfflineStatusCode = function(xhr) {
      var offlineStatusCodes, ref;
      offlineStatusCodes = Backbone.DualStorage.offlineStatusCodes;
      if (_.isFunction(offlineStatusCodes)) {
        offlineStatusCodes = offlineStatusCodes(xhr);
      }
      return xhr.status === 0 || (ref = xhr.status, indexOf.call(offlineStatusCodes, ref) >= 0);
    };
    relayErrorCallback = function(xhr) {
      var online;
      online = !hasOfflineStatusCode(xhr);
      return storeExistsPromise.always(function(storeExists) {
        options.storeExists = storeExists;
        if (online || method === 'read' && !storeExists) {
          return error(xhr);
        } else {
          return useOfflineStorage();
        }
      });
    };
    switch (method) {
      case 'read':
        return localSync('hasDirtyOrDestroyed', model, options).then(function(hasDirtyOrDestroyed) {
          if (hasDirtyOrDestroyed) {
            return useOfflineStorage();
          } else {
            options.success = function(resp, _status, _xhr) {
              var clearIfNeeded, collection, idAttribute, responseModel;
              if (hasOfflineStatusCode(options.xhr)) {
                return useOfflineStorage();
              }
              resp = parseRemoteResponse(model, resp);
              if (model instanceof Backbone.Collection) {
                collection = model;
                idAttribute = collection.model.prototype.idAttribute;
                clearIfNeeded = options.add ? $.Deferred().resolve().promise() : localSync('clear', model, options);
                return clearIfNeeded.done(function() {
                  var i, len, m, modelAttributes, models, responseModel;
                  models = [];
                  for (i = 0, len = resp.length; i < len; i++) {
                    modelAttributes = resp[i];
                    model = collection.get(modelAttributes[idAttribute]);
                    if (model) {
                      responseModel = modelUpdatedWithResponse(model, modelAttributes);
                    } else {
                      responseModel = new collection.model(modelAttributes);
                    }
                    models.push(responseModel);
                  }
                  return $.when.apply($, ((function() {
                    var j, len1, results;
                    results = [];
                    for (j = 0, len1 = models.length; j < len1; j++) {
                      m = models[j];
                      results.push(localSync('update', m, options));
                    }
                    return results;
                  })())).then(function() {
                    return success(resp, _status, _xhr);
                  });
                });
              } else {
                responseModel = modelUpdatedWithResponse(model, resp);
                return localSync('update', responseModel, options).then(function() {
                  return success(resp, _status, _xhr);
                });
              }
            };
            options.error = function(xhr) {
              return relayErrorCallback(xhr);
            };
            return options.xhr = onlineSync(method, model, options);
          }
        });
      case 'create':
        options.success = function(resp, _status, _xhr) {
          var updatedModel;
          if (hasOfflineStatusCode(options.xhr)) {
            return useOfflineStorage();
          }
          updatedModel = modelUpdatedWithResponse(model, resp);
          return localSync(method, updatedModel, options).then(function() {
            return success(resp, _status, _xhr);
          });
        };
        options.error = function(xhr) {
          return relayErrorCallback(xhr);
        };
        return options.xhr = onlineSync(method, model, options);
      case 'update':
        if (model.hasTempId()) {
          temporaryId = model.id;
          options.success = function(resp, _status, _xhr) {
            var updatedModel;
            if (hasOfflineStatusCode(options.xhr)) {
              return useOfflineStorage();
            }
            updatedModel = modelUpdatedWithResponse(model, resp);
            model.set(model.idAttribute, temporaryId, {
              silent: true
            });
            return localSync('delete', model, options).then(function() {
              return localSync('create', updatedModel, options).then(function() {
                return success(resp, _status, _xhr);
              });
            });
          };
          options.error = function(xhr) {
            model.set(model.idAttribute, temporaryId, {
              silent: true
            });
            return relayErrorCallback(xhr);
          };
          model.set(model.idAttribute, null, {
            silent: true
          });
          return options.xhr = onlineSync('create', model, options);
        } else {
          options.success = function(resp, _status, _xhr) {
            var updatedModel;
            if (hasOfflineStatusCode(options.xhr)) {
              return useOfflineStorage();
            }
            updatedModel = modelUpdatedWithResponse(model, resp);
            return localSync(method, updatedModel, options).then(function() {
              return success(resp, _status, _xhr);
            });
          };
          options.error = function(xhr) {
            return relayErrorCallback(xhr);
          };
          return options.xhr = onlineSync(method, model, options);
        }
        break;
      case 'delete':
        if (model.hasTempId()) {
          options.ignoreCallbacks = false;
          return localSync(method, model, options);
        } else {
          options.success = function(resp, _status, _xhr) {
            if (hasOfflineStatusCode(options.xhr)) {
              return useOfflineStorage();
            }
            return localSync(method, model, options).then(function() {
              return success(resp, _status, _xhr);
            });
          };
          options.error = function(xhr) {
            return relayErrorCallback(xhr);
          };
          return options.xhr = onlineSync(method, model, options);
        }
    }
  };

  Backbone.sync = dualSync;

}).call(this);

//# sourceMappingURL=backbone.dualstorage.js.map
});