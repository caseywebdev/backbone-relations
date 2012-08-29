_ = @_ or require 'underscore'

(module? and module or {}).exports = @BackboneRels =
(Backbone = @Backbone or require 'backbone') ->
  getModel = (val) -> if val instanceof Model then val else val()

  class Model extends Backbone.Model
    @new: (attributes) ->
      model = @cache.get @prototype._generateId attributes
      model?.set(arguments...) or new @ arguments...

    initialize: ->
      super arguments...
      @_previousId = @id = @_generateId()
      @constructor.cache.add @
      @_hookRels()

    _generateId: (attributes = @attributes or {}) ->
      return attributes[@idAttribute] unless @compositeKey
      vals = []
      for index in @compositeKey
        return undefined unless (val = attributes[index])?
        vals.push val
      vals.join '-'

    _hookRels: ->

      # Check for the associations definition
      return unless @rels

      # Create instance copies for modifying
      @get = _.bind @get, @
      @set = _.bind @set, @

      # Start building
      for name, rel of @rels
        if rel.hasOne
          @_hookHasOne name, rel
        else if rel.via
          @_hookHasManyVia name, rel
        else
          @_hookHasMany name, rel

    _hookHasOne: (name, rel) ->
      klass = if (k = rel.hasOne) instanceof Model then k else k()
      mine = rel.myFk

      onDestroyModel = =>
        if rel.romeo
          @trigger 'destroy', @, @collection
        else
          @set mine, null

      @set[name] = (next) =>
        prev = @get[name]
        return if next is prev
        prev.off 'destroy', onDestroyModel if prev
        @get[name] = next
        @set mine, next?.id
        next.on 'destroy', onDestroyModel if next

      @set[name] klass.new id: @get mine if @get mine

      klass.cache.on 'add', (model) =>
        @set[name] model if model.id is @get mine

      @on "change:#{mine}", =>
        @set[name] if @get mine then klass.new id: @get mine else undefined

    _hookHasMany: (name, rel) ->
      klass = getModel rel.hasMany
      theirs = rel.theirFk
      models = @get[name] = new klass.Collection
      models.url = =>
        "#{@url?() or @url}#{rel.url or "/#{name}"}"
      (models.filters = {})[theirs] = @

      klass.cache.on "add change:#{theirs}", (model) =>
        models.add model if @id is model.get theirs

      models.on "change:#{theirs}", (model) ->
        models.remove model

      models.add klass.cache.filter (model) =>
        @id is model.get theirs

    _hookHasManyVia: (name, rel) ->
      klass = getModel rel.hasMany
      viaKlass = getModel rel.via
      mine = rel.myViaFk
      theirs = rel.theirViaFk
      models = @get[name] = new klass.Collection
      models.url = =>
        "#{@url?() or @url}#{rel.url or "/#{name}"}"
      via = models.via = new viaKlass.Collection
      via.url = =>
        "#{@url?() or @url}#{viaKlass.Collection.prototype.url}"
      (via.filters = {})[mine] = @

      viaKlass.cache.on 'add', (model) =>
        via.add model if @id is model.get mine

      via
        .on('add', (model) ->
          models.add klass.new id: model.get theirs
        )
        .on 'remove', (model) ->
          models.remove models.get model.get theirs

      klass.cache.on 'add', (model) ->
        if (via.find (model2) -> model2.get theirs is model.id)
          models.add model

      models
        .on('add', (model) =>
          attributes = {}
          attributes[mine] = @id
          attributes[theirs] = model.id
          via.add viaKlass.new attributes
        )
        .on 'remove', (model) ->
          via.remove via.find (model2) ->
            model.id is model2.get theirs

      via.add viaKlass.cache.filter (model) =>
        @id is model.get mine

    via: (rel, id) ->
      id = id.id if id?.id
      @get[rel].via.find (model) =>
        id is model.get @rels[rel].theirViaFk

    change: ->
      @_previousId = @id
      @id = @_generateId()
      super arguments...

    @setup: ->
      @Collection.model = @
      @cache = new @Collection

  class Collection extends Backbone.Collection
    model: Model

    _onModelEvent: (event, model, collection, options) ->
      if model and event is 'change' and model.id isnt model._previousId
        delete @_byId[model._previousId];
        @_byId[model.id] = model if model.id?
      super arguments...

    fetch: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      options.success = (resp, status, xhr) =>
        models = []
        models.push = @model.new attrs for attrs in @parse resp
        @remove @models unless options.add
        @add resp
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

  {Model, Collection}

@BackboneRels = @BackboneRels() if Backbone?
