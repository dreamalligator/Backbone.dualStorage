{backboneSync, localSync, dualSync, localStorage} = window
{Collection, Model} = {}

describe 'Backbone.dualStorage', ->
  @timeout 100

  beforeEach ->
    localStorage.clear()
    class Model extends Backbone.Model
      idAttribute: '_id'
      urlRoot: 'things/'
    class Collection extends Backbone.Collection
      model: Model
      url: Model::urlRoot

  describe 'basic persistence', ->
    describe 'online operations cached for offline use', ->
      describe 'Model.fetch', ->
        it 'stores the result locally after fetch', (done) ->
          fetchedOnline = $.Deferred()
          model = new Model _id: 1
          model.fetch serverResponse: {_id: 1, pants: 'fancy'}, success: ->
            fetchedOnline.resolve()
          fetchedOnline.done ->
            fetchedLocally = $.Deferred()
            model = new Model _id: 1
            model.fetch remote: false, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(model.get('pants')).to.equal 'fancy'
              done()

        it 'replaces previously fetched data in local storage when fetched again', (done) ->
          fetch1 = $.Deferred()
          model = new Model _id: 1
          model.fetch serverResponse: {_id: 1, pants: 'fancy'}, success: ->
            fetch1.resolve()
          fetch1.done ->
            fetch2 = $.Deferred()
            model = new Model _id: 1
            model.fetch serverResponse: {_id: 1, shoes: 'boots'}, success: ->
              fetch2.resolve()
            fetch2.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('pants')).to.be.undefined
                expect(model.get('shoes')).to.equal 'boots'
                done()

      describe 'Model.save', ->
        describe 'creating a new model', ->
          it 'stores saved attributes locally', (done) ->
            saved = $.Deferred()
            model = new Model
            model.save 'paper', 'oragami', serverResponse: {_id: 1, paper: 'oragami'}, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('paper')).to.equal 'oragami'
                done()

          it 'updates the model with changes in the server response', (done) ->
            saved = $.Deferred()
            model = new Model role: 'admin', action: 'escalating privileges'
            response =        role: 'peon',  action: 'escalating privileges', _id: 1, updated_at: '2014-07-04 00:00:00'
            model.save null, serverResponse: response, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.attributes).to.eql response
                done()

        describe 'updating an existing model', ->
          it 'stores saved attributes locally', (done) ->
            saved = $.Deferred()
            model = new Model _id: 1
            model.save 'paper', 'oragami', success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('paper')).to.equal 'oragami'
                done()

          it 'updates the model with changes in the server response', (done) ->
            saved = $.Deferred()
            model = new Model _id: 1, role: 'admin', action: 'escalating privileges'
            response =        _id: 1, role: 'peon',  action: 'escalating privileges', updated_at: '2014-07-04 00:00:00'
            model.save null, serverResponse: response, success: ->
              saved.resolve()
            saved.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: 1
              model.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.attributes).to.eql response
                done()

          it 'replaces previously saved attributes when saved again', (done) ->
            saved1 = $.Deferred()
            model = new Model _id: 1
            model.save 'paper', 'hats', success: ->
              saved1.resolve()
            saved1.done ->
              saved2 = $.Deferred()
              model = new Model _id: 1
              model.save 'leather', 'belts', success: ->
                saved2.resolve()
              saved2.done ->
                fetchedLocally = $.Deferred()
                model = new Model _id: 1
                model.fetch remote: false, success: ->
                  fetchedLocally.resolve()
                fetchedLocally.done ->
                  expect(model.get('paper')).to.be.undefined
                  expect(model.get('leather')).to.equal 'belts'
                  done()

      describe 'Model.destroy', ->
        it 'removes the locally stored version', (done) ->
          saved = $.Deferred()
          model = new Model _id: 1
          model.save null, success: ->
            saved.resolve()
          saved.done ->
            destroyed = $.Deferred()
            model = new Model _id: 1
            model.destroy success: ->
              destroyed.resolve()
            destroyed.done ->
              model = new Model _id: 1
              model.fetch remote: false, error: -> done()

        it "doesn't error if there was no locally stored version", (done) ->
          destroyed = $.Deferred()
          model = new Model _id: 1
          model.destroy success: -> done()

      describe 'Collection.fetch', ->
        it 'stores each model locally', (done) ->
          fetched = $.Deferred()
          response_collection = [
            {_id: 1, hair: 'strawberry'},
            {_id: 2, hair: 'burgundy'}
          ]
          collection = new Collection
          collection.fetch serverResponse: response_collection, success: ->
            fetched.resolve()
          fetched.done ->
            expect(collection.length).to.equal 2
            fetchedLocally = $.Deferred()
            collection = new Collection
            collection.fetch remote: false, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(collection.length).to.equal 2
              expect(collection.map (model) -> model.id).to.eql [1,2]
              expect(collection.get(2).get('hair')).to.equal 'burgundy'
              done()

        it 'replaces the existing local collection', (done) ->
          saved = $.Deferred()
          model = new Model _id: 3, hair: 'chocolate'
          model.save null, success: ->
            saved.resolve()
          saved.done ->
            fetched = $.Deferred()
            response_collection = [
              {_id: 1, hair: 'strawberry'},
              {_id: 2, hair: 'burgundy'}
            ]
            collection = new Collection
            collection.fetch serverResponse: response_collection, success: ->
              fetched.resolve()
            fetched.done ->
              fetchedLocally = $.Deferred()
              collection = new Collection
              collection.fetch remote: false, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
              expect(collection.length).to.equal 2
              expect(collection.map (model) -> model.id).to.eql [1,2]
              done()

        describe 'options: {add: true}', ->
          it 'adds to the existing local collection', (done) ->
            saved = $.Deferred()
            model = new Model _id: 3, hair: 'chocolate'
            model.save null, success: ->
              saved.resolve()
            saved.done ->
              fetched = $.Deferred()
              response_collection = [
                {_id: 1, hair: 'strawberry'},
                {_id: 2, hair: 'burgundy'}
              ]
              collection = new Collection
              collection.fetch add: true, serverResponse: response_collection, success: ->
                fetched.resolve()
              fetched.done ->
                fetchedLocally = $.Deferred()
                collection = new Collection
                collection.fetch remote: false, success: ->
                  fetchedLocally.resolve()
                fetchedLocally.done ->
                  expect(collection.length).to.equal 3
                  expect(collection.map (model) -> model.id).to.include.members [1,2,3]
                  done()

          describe 'options: {add: true, merge: false}', ->
            it '(FAILS; DISABLED) does not update attributes on existing local models', (done) ->
              return done()
              saved = $.Deferred()
              model = new Model _id: 3, hair: 'chocolate'
              model.save null, success: ->
                saved.resolve()
              saved.done ->
                fetched = $.Deferred()
                response_collection = [
                  {_id: 1, hair: 'strawberry'},
                  {_id: 2, hair: 'burgundy'},
                  {_id: 3, hair: 'white chocolate'}
                ]
                collection = new Collection
                collection.fetch add: true, merge: false, serverResponse: response_collection, success: ->
                  fetched.resolve()
                fetched.done ->
                  fetchedLocally = $.Deferred()
                  collection = new Collection
                  collection.fetch remote: false, success: ->
                    fetchedLocally.resolve()
                  fetchedLocally.done ->
                    expect(collection.length).to.equal 3
                    expect(collection.get(3).get('hair')).to.equal 'chocolate'
                    done()

    describe 'offline operations cached for syncing later', ->
      describe 'Model.save, Model.fetch', ->
        it 'creates new records', (done) ->
          saved = $.Deferred()
          model = new Model
          model.save 'paper', 'oragami', errorStatus: 0, success: ->
            saved.resolve()
          saved.done ->
            fetchedLocally = $.Deferred()
            model = new Model _id: model.id
            model.fetch errorStatus: 0, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(model.get('paper')).to.equal 'oragami'
              done()

        it 'updates records created while offline', (done) ->
          saved = $.Deferred()
          model = new Model
          model.save 'paper', 'oragami', errorStatus: 0, success: ->
            saved.resolve()
          saved.done ->
            updated = $.Deferred()
            model.save 'paper', 'mâché', errorStatus: 0, success: ->
              updated.resolve()
            updated.done ->
              fetchedLocally = $.Deferred()
              model = new Model _id: model.id
              model.fetch errorStatus: 0, success: ->
                fetchedLocally.resolve()
              fetchedLocally.done ->
                expect(model.get('paper')).to.equal 'mâché'
                done()

      describe 'Collection.fetch', ->
        it 'loads models that were saved with a common storeName/urlRoot', (done) ->
          saved1 = $.Deferred()
          model1 = new Model a: 1
          model1.save 'paper', 'oragami', errorStatus: 0, success: ->
            saved1.resolve()
          saved2 = $.Deferred()
          model2 = new Model a: 2
          model2.save 'paper', 'oragami', errorStatus: 0, success: ->
            saved2.resolve()
          $.when(saved1, saved2).done ->
            fetched = $.Deferred()
            collection = new Collection
            collection.fetch errorStatus: 0, success: ->
              fetched.resolve()
            fetched.done ->
              expect(collection.size()).to.equal 2
              expect(collection.get(model1.id).attributes).to.eql model1.attributes
              expect(collection.get(model2.id).attributes).to.eql model2.attributes
              done()

      describe 'Model.id', ->
        it 'obtains a temporary id on new records for use until saved online', (done) ->
          saved = $.Deferred()
          model = new Model
          model.save null, errorStatus: 0, success: ->
            saved.resolve()
          saved.done ->
            expect(model.id.length).to.equal 36
            done()

  describe 'syncing offline changes when there are dirty or destroyed records', ->
    beforeEach (done) ->
      # Save two models in a collection while online.
      # Then while offline, modify one, and delete the other
      @collection = new Collection [
        {_id: 1, name: 'change me'},
        {_id: 2, name: 'delete me'}
      ]
      allSaved = @collection.map (model) ->
        saved = $.Deferred()
        model.save null, success: ->
          saved.resolve()
        saved
      allModified = $.when(allSaved...).then =>
        dirtied = $.Deferred()
        @collection.get(1).save 'name', 'dirty me', errorStatus: 0, success: ->
          dirtied.resolve()
        destroyed = $.Deferred()
        @collection.get(2).destroy errorStatus: 0, success: ->
          destroyed.resolve()
        $.when dirtied, destroyed
      allModified.done ->
        done()

    describe 'Model.fetch', ->
      it 'reads models in dirty collections from local storage until a successful sync', (done) ->
        fetched = $.Deferred()
        model = new Model _id: 1
        model.fetch serverResponse: {_id: 1, name: 'this response is never used'}, success: ->
          fetched.resolve()
        fetched.done ->
          expect(model.get('name')).to.equal 'dirty me'
          done()

    describe 'Collection.fetch', ->
      it 'excludes destroyed models when working locally before a sync', (done) ->
        fetched = $.Deferred()
        collection = new Collection
        collection.fetch serverResponse: [{_id: 3, name: 'this response is never used'}], success: ->
          fetched.resolve()
        fetched.done ->
          expect(collection.size()).to.equal 1
          expect(collection.first().get('name')).to.equal 'dirty me'
          done()

    describe 'Collection.dirtyModels', ->
      it 'returns an array of models that have been created or updated while offline', ->
        expect(@collection.dirtyModels()).to.eql [@collection.get(1)]

    describe 'Collection.destroyedModelIds', ->
      it 'returns an array of ids for models that have been destroyed while offline', ->
        expect(@collection.destroyedModelIds()).to.eql ['2']

    # These sync methods are synchronous only in this test environment.
    # The async branch will provide a promise that we can use to know when it completes.
    # In the current version, there is no callback.

    describe 'Collection.syncDirty', ->
      it 'attempts to save online all records that were created/updated while offline', ->
        backboneSync.reset()
        @collection.syncDirty(async: false)
        expect(backboneSync.callCount).to.equal 1
        expect(@collection.dirtyModels()).to.eql []

    describe 'Collection.syncDestroyed', ->
      it 'attempts to destroy online all records that were destroyed while offline', ->
        backboneSync.reset()
        @collection.syncDestroyed(async: false)
        expect(backboneSync.callCount).to.equal 1
        expect(@collection.destroyedModelIds()).to.eql []

    describe 'Collection.syncDirtyAndDestroyed', ->
      it 'attempts to sync online all records that were modified while offline', ->
        backboneSync.reset()
        @collection.syncDirtyAndDestroyed(async: false)
        expect(backboneSync.callCount).to.equal 2
        expect(@collection.dirtyModels()).to.eql []
        expect(@collection.destroyedModelIds()).to.eql []

    describe 'Model.destroy', ->
      it 'does not mark models for deletion that were created and destroyed offline', (done) ->
        model = new Model name: 'transient'
        @collection.add model
        model.save null, errorStatus: 0
        destroyed = $.Deferred()
        model.destroy errorStatus: 0, success: -> destroyed.resolve()
        destroyed.done =>
          backboneSync.reset()
          @collection.syncDestroyed()
          expect(backboneSync.callCount).to.equal 1
          expect(backboneSync.firstCall.args[1].id).not.to.equal model.id
          done()

    describe 'Model.id', ->
      it 'for new records with a temporary id is replaced by the id returned by the server', (done) ->
        saved = $.Deferred()
        model = new Model
        @collection.add model
        model.save 'name', 'created while offline', errorStatus: 0, success: ->
          saved.resolve()
        saved.done =>
          expect(model.id.length).to.equal 36
          backboneSync.reset()
          @collection.syncDirty()
          expect(backboneSync.callCount).to.equal 2
          expect(backboneSync.lastCall.args[0]).to.equal 'create'
          expect(backboneSync.lastCall.args[1].id).to.be.null
          expect(backboneSync.lastCall.args[1].get('_id')).to.be.null
          done()

  describe 'mode overrides', ->
    describe 'via properties', ->
      describe 'Model.local', ->
        it 'uses only local storage when true', (done) ->
          class LocalModel extends Model
            local: true
          model = new LocalModel
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 0
            done()

        it 'does not mark local changes dirty and will not sync them (deprecated; will sync after 2.0)', (done) ->
          class LocalModel extends Model
            local: true
          model = new LocalModel
          collection = new Collection [model]
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 0
            collection.syncDirtyAndDestroyed()
            expect(backboneSync.callCount).to.equal 0
            done()

      describe 'Model.remote', ->
        it 'uses only remote storage when true', (done) ->
          class RemoteModel extends Model
            remote: true
          model = new RemoteModel _id: 1
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 1
            model.fetch errorStatus: 0, error: -> done()

      describe 'Collection.local', ->
        it 'uses only local storage when true', (done) ->
          class LocalCollection extends Collection
            local: true
          collection = new LocalCollection
          backboneSync.reset()
          fetched = $.Deferred()
          collection.fetch success: -> fetched.resolve()
          fetched.done ->
            expect(backboneSync.callCount).to.equal 0
            done()

      describe 'Collection.remote', ->
        it 'uses only remote storage when true', (done) ->
          class RemoteCollection extends Collection
            remote: true
          collection = new RemoteCollection _id: 1
          backboneSync.reset()
          fetched = $.Deferred()
          collection.fetch success: -> fetched.resolve()
          fetched.done ->
            expect(backboneSync.callCount).to.equal 1
            collection.fetch errorStatus: 0, error: -> done()

    describe 'via methods, dynamically', ->
      describe 'Model.local', ->
        it 'uses only local storage when the function returns true', (done) ->
          class LocalModel extends Model
            local: -> true
          model = new LocalModel
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 0
            done()

      describe 'Model.remote', ->
        it 'uses only remote storage when the function returns true', (done) ->
          class RemoteModel extends Model
            remote: -> true
          model = new RemoteModel _id: 1
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 1
            model.fetch errorStatus: 0, error: -> done()

      describe 'Collection.local', ->
        it 'uses only local storage when the function returns true', (done) ->
          class LocalCollection extends Collection
            local: -> true
          collection = new LocalCollection
          backboneSync.reset()
          fetched = $.Deferred()
          collection.fetch success: -> fetched.resolve()
          fetched.done ->
            expect(backboneSync.callCount).to.equal 0
            done()

      describe 'Collection.remote', ->
        it 'uses only remote storage when the function returns true', (done) ->
          class RemoteCollection extends Collection
            remote: -> true
          collection = new RemoteCollection _id: 1
          backboneSync.reset()
          fetched = $.Deferred()
          collection.fetch success: -> fetched.resolve()
          fetched.done ->
            expect(backboneSync.callCount).to.equal 1
            collection.fetch errorStatus: 0, error: -> done()

    describe 'via options', ->
      describe '{remote: false}', ->
        it 'uses local storage as if offline', (done) ->
          model = new Model
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, remote: false, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 0
            done()

        it 'marks records dirty, to be synced when online', (done) ->
          model = new Model
          collection = new Collection [model]
          backboneSync.reset()
          saved = $.Deferred()
          model.save null, remote: false, success: -> saved.resolve()
          saved.done ->
            expect(backboneSync.callCount).to.equal 0
            collection.syncDirtyAndDestroyed()
            expect(backboneSync.callCount).to.equal 1
            done()

  describe 'offline detection', ->
    describe 'Backbone.DualStorage.offlineStatusCodes', ->
      beforeEach -> @originalOfflineStatusCodes = Backbone.DualStorage.offlineStatusCodes
      afterEach -> Backbone.DualStorage.offlineStatusCodes = @originalOfflineStatusCodes

      describe 'as an array property', ->
        it 'acts as offline when a server response code is in included in the array', (done) ->
          Backbone.DualStorage.offlineStatusCodes = [500, 502]
          model = new Model _id: 1
          saved = $.Deferred()
          model.save 'name', 'original name saved locally', success: -> saved.resolve()
          saved.done ->
            model = new Model _id: 1
            fetchedLocally = $.Deferred()
            response = 'response ignored because of the "offline" status code'
            model.fetch errorStatus: 500, serverResponse: {name: response}, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(model.get('name')).to.equal 'original name saved locally'
              done()

        it 'defaults to [408, 502] (Request Timeout, Bad Gateway)', ->
          expect(Backbone.DualStorage.offlineStatusCodes).to.eql [408, 502]

      describe 'as an array returned by a method', ->
        it 'acts as offline when a server response code is in included in the array', (done) ->
          serverReportsToBeOffline = (xhr) ->
            if xhr?.response?['error_message'] == 'Offline for maintenance'
              [200]
            else
              []
          Backbone.DualStorage.offlineStatusCodes = serverReportsToBeOffline
          model = new Model _id: 1
          saved = $.Deferred()
          model.save 'name', 'original name saved locally', success: -> saved.resolve()
          saved.done ->
            model = new Model _id: 1
            fetchedLocally = $.Deferred()
            model.fetch serverResponse: {_id: 1, name: 'unknown', error_message: 'Offline for maintenance'}, success: ->
              fetchedLocally.resolve()
            fetchedLocally.done ->
              expect(model.get('name')).to.equal 'original name saved locally'
              done()

      it 'treats an ajax response status code 0 as offline, regardless of offlineStatusCodes', (done) ->
        model = new Model _id: 1
        saved = $.Deferred()
        model.save 'name', 'original name saved locally', success: -> saved.resolve()
        saved.done ->
          model = new Model _id: 1
          fetchedLocally = $.Deferred()
          response = 'response ignored because of the "offline" status code'
          model.fetch errorStatus: 0, serverResponse: {name: response}, success: ->
            fetchedLocally.resolve()
          fetchedLocally.done ->
            expect(model.get('name')).to.equal 'original name saved locally'
            done()

  describe 'callbacks', ->
    describe 'when offline', ->
      describe 'with no local store initialized for the model/collection', ->
        beforeEach ->
          @model = new Model

        it 'calls the error callback', (done) ->
          @model.fetch errorStatus: 0, error: -> done()

        it 'fails the deferred promise'

        it 'triggers the error event', (done) ->
          @model.on 'error', -> done()
          @model.fetch errorStatus: 0

      describe 'with a local store initialized', ->
        beforeEach (done) ->
          @model = new Model
          @model.save null, errorStatus: 0, success: -> done()

        it 'calls the success callback', (done) ->
          @model.fetch errorStatus: 0, success: -> done()

        it 'resolves the deferred promise'

        it 'triggers the sync event', (done) ->
          @model.on 'sync', -> done()
          @model.fetch errorStatus: 0

      describe 'when fetching an id that is not cached', ->
        beforeEach (done) ->
          model = new Model _id: 1
          model.save null, errorStatus: 0, success: -> done()

        it 'calls the error callback', (done) ->
          model = new Model _id: 999
          model.fetch errorStatus: 0, error: -> done()

        it 'fails the deferred promise'

        it 'triggers the error event', (done) ->
          model = new Model _id: 999
          model.on 'error', -> done()
          model.fetch errorStatus: 0

      describe 'the dirty attribute', ->
        beforeEach (done) ->
          @model = new Model
          @model.save null, errorStatus: 0, success: -> done()

        it 'is set in the callback options', (done) ->
          @model.fetch errorStatus: 0, success: (model, reponse, options) ->
            expect(options.dirty).to.be.true
            done()

        it 'is set in the promise doneCallback options'

        it 'is set in the sync event options', (done) ->
          @model.on 'sync', (model, response, options) ->
            expect(options.dirty).to.be.true
            done()
          @model.fetch errorStatus: 0

    describe 'when online', ->
      describe 'receiving an error response', ->
        beforeEach ->
          @model = new Model

        it 'calls the error callback', (done) ->
          @model.fetch errorStatus: 500, error: -> done()

        it 'fails the deferred promise'

        it 'triggers the error event', (done) ->
          @model.on 'error', -> done()
          @model.fetch errorStatus: 500

      describe 'receiving a successful response', ->
        beforeEach ->
          @model = new Model _id: 1

        it 'calls the success callback', (done) ->
          @model.fetch success: -> done()

        it 'resolves the deferred promise'

        it 'triggers the sync event', (done) ->
          @model.on 'sync', -> done()
          @model.fetch()

      describe 'the dirty attribute', ->
        beforeEach (done) ->
          @model = new Model
          @model.save '_id', '1', success: -> done()

        it 'is set in the callback options', (done) ->
          @model.fetch success: (model, reponse, options) ->
            expect(options.dirty).not.to.be.true
            done()

        it 'is set in the promise doneCallback options'

        it 'is set in the sync event options', (done) ->
          @model.on 'sync', (model, response, options) ->
            expect(options.dirty).not.to.be.true
            done()
          @model.fetch()

  describe 'pre-parsing', ->
    beforeEach ->
      Model::parse = (response) ->
        response.phrase = response.phrase?.replace /!/, ' parseWasHere'
        response
      Model::parseBeforeLocalSave = (unformattedReponse) ->
        _id: 1
        phrase: unformattedReponse
      Collection::parse = (response) ->
        i = 0
        for item in response
          _.extend item, order: i++
          item
      Collection::parseBeforeLocalSave = (response) ->
        _.map response, (item) ->
          _id: item

    describe 'Model.parseBeforeLocalSave', ->
      describe 'on fetch', ->
        it 'transforms the response into a hash of attributes with an id', (done) ->
          model = new Model
          fetched = $.Deferred()
          model.fetch serverResponse: 'Hi!!', success: -> fetched.resolve()
          fetched.done ->
            expect(model.id).to.equal 1
            expect(model.get('phrase')).not.to.be.null
            done()

    describe 'Model.parse', ->
      describe 'when used alongside parseBeforeLocalSave', ->
        it 'modifies attributes in the response to fit an API response to the backbone model', (done) ->
          model = new Model
          fetched = $.Deferred()
          model.fetch serverResponse: 'Hi!', success: -> fetched.resolve()
          fetched.done ->
            expect(model.get('phrase')).to.equal 'Hi parseWasHere'
            done()

        it 'bug: parse should not be called twice on the response'
          # model = new Model
          # fetched = $.Deferred()
          # model.fetch serverResponse: 'Hi!!', success: -> fetched.resolve()
          # fetched.done ->
          #   expect(model.get('phrase')).to.equal 'Hi parseWasHere!'
          #   done()

    describe 'Collection.parseBeforeLocalSave', ->
      describe 'on fetch', ->
        it 'transforms the response into an array of hash attributes with an id', (done) ->
          collection = new Collection
          fetched = $.Deferred()
          collection.fetch serverResponse: ['a', 'b'], success: -> fetched.resolve()
          fetched.done ->
            expect(collection.get('a')).not.to.be.null
            expect(collection.get('b')).not.to.be.null
            done()

    describe 'Collection.parse', ->
      describe 'when used alongside parseBeforeLocalSave', ->
        it 'modifies objects in the response to fit an API response to the backbone model', (done) ->
          collection = new Collection
          fetched = $.Deferred()
          collection.fetch serverResponse: ['a', 'b'], success: -> fetched.resolve()
          fetched.done ->
            expect(collection.get('a').get('order')).to.equal 0
            expect(collection.get('b').get('order')).to.equal 1
            done()

  describe 'storeName', ->
    it 'uses the same store for models with the same storeName', (done) ->
      class OneModel extends Backbone.Model
        storeName: '/samePlace'
      class AnotherModel extends Backbone.Model
        storeName: '/samePlace'
      saved = $.Deferred()
      model = new OneModel
      model.save 'paper', 'oragami', errorStatus: 0, success: ->
        saved.resolve()
      saved.done ->
        fetchedLocally = $.Deferred()
        model = new AnotherModel id: model.id
        model.fetch errorStatus: 0, success: ->
          fetchedLocally.resolve()
        fetchedLocally.done ->
          expect(model.get('paper')).to.equal 'oragami'
          done()

    describe 'Model.url', ->
      it 'is used as the store name, lacking anything below', (done) ->
        class OneModel extends Backbone.Model
          url: '/someplace'
        class AnotherModel extends Backbone.Model
          url: '/anotherPlace'
        saved = $.Deferred()
        model = new OneModel
        model.save 'paper', 'oragami', errorStatus: 0, success: ->
          saved.resolve()
        saved.done ->
          model = new AnotherModel id: model.id
          model.fetch errorStatus: 0, error: ->
            done()

    describe 'Model.urlRoot', ->
      it 'is used as the store name, lacking anything below', (done) ->
        class OneModel extends Backbone.Model
          url: '/samePlace'
          urlRoot: '/onePlace'
        class AnotherModel extends Backbone.Model
          url: '/samePlace'
          urlRoot: '/anotherPlce'
        saved = $.Deferred()
        model = new OneModel
        model.save 'paper', 'oragami', errorStatus: 0, success: ->
          saved.resolve()
        saved.done ->
          model = new AnotherModel id: model.id
          model.fetch errorStatus: 0, error: ->
            done()

    describe 'Collection.url', ->
      it 'is used as the store name, lacking anything below', (done) ->
        class MatchingCollection extends Backbone.Collection
          model: Model
          url: 'things/'
        class DisconnectedCollection extends Backbone.Collection
          model: Model
          url: 'does_not_match_the_model/'
        saved = $.Deferred()
        model = new Model
        model.save 'paper', 'oragami', errorStatus: 0, success: ->
          saved.resolve()
        saved.done ->
          collection = new MatchingCollection
          collection.fetch errorStatus: 0, success: ->
            expect(collection.size()).to.eql 1
            collection = new DisconnectedCollection
            collection.fetch errorStatus: 0, error: ->
              done()

    describe 'Model.storeName', ->
      it 'is used as the store name, lacking anything below', (done) ->
        class OneModel extends Backbone.Model
          urlRoot: 'commonURL/'
          storeName: 'someName'
        class AnotherModel extends Backbone.Model
          urlRoot: 'commonURL/'
          storeName: 'anotherName'
        saved = $.Deferred()
        model = new OneModel
        model.save 'paper', 'oragami', errorStatus: 0, success: ->
          saved.resolve()
        saved.done ->
          model = new AnotherModel id: model.id
          model.fetch errorStatus: 0, error: ->
            done()

    describe 'Collection.storeName', ->
      it 'is used as the store name if given', (done) ->
        class MatchingCollection extends Backbone.Collection
          model: Model
          url: 'commonURL/'
          storeName: 'things/'
        class DisconnectedCollection extends Backbone.Collection
          model: Model
          url: 'commonURL/'
          storeName: 'does_not_match_the_model/'
        saved = $.Deferred()
        model = new Model
        model.save 'paper', 'oragami', errorStatus: 0, success: ->
          saved.resolve()
        saved.done ->
          collection = new MatchingCollection
          fetchedMatching = $.Deferred()
          collection.fetch errorStatus: 0, success: -> fetchedMatching.resolve()
          fetchedMatching.done ->
            expect(collection.size()).to.eql 1
            collection = new DisconnectedCollection
            collection.fetch errorStatus: 0, error: ->
              done()