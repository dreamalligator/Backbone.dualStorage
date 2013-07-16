// Generated by CoffeeScript 1.6.3
(function() {
  describe('monkey patching', function() {
    return it('aliases Backbone.sync to backboneSync', function() {
      expect(window.backboneSync).toBeDefined();
      return expect(window.backboneSync.identity).toEqual('sync');
    });
  });

  describe('offline localStorage sync', function() {
    var collection;
    collection = {}.collection;
    beforeEach(function() {
      window.localStorage.clear();
      window.localStorage.setItem('cats', '2,3,a');
      window.localStorage.setItem('cats_dirty', '2,a');
      window.localStorage.setItem('cats_destroyed', '3');
      window.localStorage.setItem('cats3', '{"id": "2", "color": "auburn"}');
      window.localStorage.setItem('cats3', '{"id": "3", "color": "burgundy"}');
      window.localStorage.setItem('cats3', '{"id": "a", "color": "scarlet"}');
      collection = new window.Backbone.Collection([
        {
          id: 2,
          color: 'auburn'
        }, {
          id: 3,
          color: 'burgundy'
        }, {
          id: 'a',
          color: 'burgundy'
        }
      ]);
      return collection.url = function() {
        return 'cats';
      };
    });
    describe('syncDirtyAndDestroyed', function() {
      return it('calls syncDirty and syncDestroyed', function() {
        var syncDestroyed, syncDirty;
        syncDirty = spyOn(window.Backbone.Collection.prototype, 'syncDirty');
        syncDestroyed = spyOn(window.Backbone.Collection.prototype, 'syncDestroyed');
        collection.syncDirtyAndDestroyed();
        expect(syncDirty).toHaveBeenCalled();
        return expect(syncDestroyed).toHaveBeenCalled();
      });
    });
    describe('syncDirty', function() {
      return it('finds and saves all dirty models', function() {
        var saveInteger, saveString;
        saveInteger = spyOn(collection.get(2), 'save').andCallThrough();
        saveString = spyOn(collection.get('a'), 'save').andCallThrough();
        collection.syncDirty();
        expect(saveInteger).toHaveBeenCalled();
        expect(saveString).toHaveBeenCalled();
        return expect(window.localStorage.getItem('cats_dirty')).toBeFalsy();
      });
    });
    return describe('syncDestroyed', function() {
      return it('finds all models marked as destroyed and destroys them', function() {
        var destroy;
        destroy = spyOn(collection.get(3), 'destroy');
        collection.syncDestroyed();
        return expect(window.localStorage.getItem('cats_destroyed')).toBeFalsy();
      });
    });
  });

}).call(this);
