_ = @_ or require 'underscore'

bind = (Backbone = @Backbone or require 'backbone') ->
  class Model extends Backbone.Model

    # Return the cache collection for this model
    @cache: -> @_cache or= new @Collection

    # `cache` instance alias
    cache: -> @constructor.cache()

    # Search the cache first, then return a new model
    @new: (attrs) ->
      model = @cache().get @prototype._generateId attrs
      model?.set(arguments...) or new @ arguments...

    # `new` instance alias
    new: -> @constructor.new arguments...

    initialize: ->
      super
      @_previousId = @id = @_generateId()
      @cache().add @
      @_hookRels()

    _generateId: (attrs = @attributes) ->
      return attrs[@idAttribute] unless @compositeKey
      vals = []
      for index in @compositeKey
        return undefined unless (val = attrs[index])?
        vals.push val
      vals.join '-'

    _hookRels: ->

      # Check for the associations definition
      return unless @rels

      # Create copies for modifying
      @get = _.bind @get, @
      @set = _.bind @set, @

      # Start hooking (that sounds scandalous)
      for name, rel of @rels
        if rel.hasOne
          @_hookHasOne name, rel
        else if rel.via
          @_hookHasManyVia name, rel
        else
          @_hookHasMany name, rel

    _hookHasOne: (name, rel) ->
      ctor = getCtor rel.hasOne
      mine = rel.myFk

      onChangeId = =>
        @set mine, @get[name].id

      onDestroy = =>
        delete @get[name]
        if rel.romeo
          @trigger 'destroy', @, @collection
        else
          @set mine, null

      @set[name] = (next) =>
        prev = @get[name]
        return if next is prev
        if prev
          prev.off 'change:id', onChangeId
          prev.off 'destroy', onDestroy
        @get[name] = next
        @set mine, next?.id
        if next
          next.on 'change:id', onChangeId
          next.on 'destroy', onDestroy

      (onChangeMine = =>
        @set[name] ctor.cache().get @get mine
      )()

      @on "change:#{mine}", onChangeMine

      ctor.cache().on 'add', (model) =>
        @set[name] model if model.id is @get mine

    _hookHasMany: (name, rel) ->
      ctor = getCtor rel.hasMany
      theirs = rel.theirFk
      models = @get[name] = new ctor.Collection
      models.url = =>
        "#{@url?() or @url}#{rel.url or "/#{name}"}"
      (models.filters = {})[theirs] = @

      ctor.cache().on "add change:#{theirs}", (model) =>
        models.add model if @id is model.get theirs

      models.on "change:#{theirs}", (model) ->
        models.remove model

      models.add ctor.cache().filter (model) =>
        @id is model.get theirs

    _hookHasManyVia: (name, rel) ->
      ctor = getCtor rel.hasMany
      viaCtor = getCtor rel.via
      mine = rel.myViaFk
      theirs = rel.theirViaFk
      models = @get[name] = new ctor.Collection
      models.url = =>
        "#{@url?() or @url}#{rel.url or "/#{name}"}"
      via = models.via = new viaCtor.Collection
      via.url = => "#{@url?() or @url}#{viaCtor.Collection::url}"
      (via.filters = {})[mine] = @

      viaCtor.cache().on 'add', (model) =>
        via.add model if @id is model.get mine

      via
        .on('add', (model) ->
          models.add ctor.new id: model.get theirs
        )
        .on 'remove', (model) ->
          models.remove models.get model.get theirs

      ctor.cache().on 'add', (model) ->
        if (via.find (model2) -> model2.get theirs is model.id)
          models.add model

      models
        .on('add', (model) =>
          attributes = {}
          attributes[mine] = @id
          attributes[theirs] = model.id
          via.add viaCtor.new attributes
        )
        .on 'remove', (model) ->
          via.remove via.find (model2) ->
            model.id is model2.get theirs

      via.add viaCtor.cache().filter (model) =>
        @id is model.get mine

    via: (rel, id) ->
      id = id.id if id?.id
      @get[rel].via.find (model) =>
        id is model.get @rels[rel].theirViaFk

    # Override to account for composite keys
    change: ->
      @_previousId = @id
      @id = @_generateId()
      super

  class Collection extends Backbone.Collection
    model: Model

    _onModelEvent: (event, model, collection, options) ->
      if model and event is 'change' and model.id isnt model._previousId
        delete @_byId[model._previousId];
        @_byId[model.id] = model if model.id?
      super

    fetch: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      options.success = (resp, status, xhr) =>
        models = []
        models.push @model.new attrs for attrs in @parse resp
        @remove @models unless options.add
        @add models
        success? @, resp, options
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return (@sync or Backbone.sync) 'read', this, options

    save: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      return success? @, [], options unless @length
      options.success = (resp, status, xhr) =>
        @at(i).set attrs, xhr for attrs, i in @parse resp
        success? @, resp, options
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return (@sync or Backbone.sync) 'update', this, options

    destroy: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      options.success = (resp) ->
        for model in @models
          model.trigger 'destroy', model, model.collection, options
        success? @, resp, options
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return (@sync or Backbone.sync) 'delete', @, options

  getCtor = (val) -> if val instanceof Model then val else val()

  Backbone.Rels = {Model, Collection}

(module? and module or {}).exports = Rels = (Backbone) ->
  _.extend @constructor, bind Backbone
_.extend Rels, bind()
