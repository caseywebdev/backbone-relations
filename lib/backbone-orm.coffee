_ = @_ or require 'underscore'

(module? and module or {}).exports = @BackboneOrm =
(Backbone = @Backbone or require 'backbone') ->
  getModel = (val) -> if val instanceof Model then val else val()

  class Model extends Backbone.Model
    @new: (attributes) ->
      model = @cache.get @prototype._generateId attributes
      model?.set(arguments...) or new @ arguments...

    initialize: ->
      super arguments...
      @_previousId = @id = @_generateId()
      @_hookRelations()
      @constructor.cache.add @

    _generateId: (attributes = @attributes or {}) ->
      return attributes[@idAttribute] unless @compositeKey
      vals = []
      for index in @compositeKey
        return undefined unless (val = attributes[index])?
        vals.push val
      vals.join '-'

    _hookRelations: ->

      # Check for the relations definition
      return unless @relations

      # Create instance copies for modifying
      @get = _.bind @get, @
      @set = _.bind @set, @

      # Collect groups and hook them after the relations
      groups = {}

      # Start building
      for name, rel of @relations
        if _.isArray rel
          groups[name] = rel
        else if rel.hasOne
          @_hookHasOne name, rel
        else if rel.via
          @_hookHasManyVia name, rel
        else
          @_hookHasMany name, rel

      for name, rels of groups
        @_hookGroup name, rels

    _hookHasOne: (name, rel) ->
      klass = if (k = rel.hasOne) instanceof Model then k else k()
      mine = rel.myFk

      onIdChange = =>
        @set mine, @get[name].id

      onDestroyModel = =>
        if rel.romeo
          @trigger 'destroy', @, @collection
        else
          @set mine, null

      (@set[name] = (next = klass.cache.get @get mine) =>
        return unless next
        prev = @get[name]
        return if next is prev
        if prev
          prev.off 'change:id', onIdChange
          prev.off 'destroy', onDestroyModel
        @get[name] = next
        @set mine, next.id
        next.on 'change:id', onIdChange
        next.on 'destroy', onDestroyModel
      )()

      klass.cache.on 'add', (model) =>
        if model.id is @get mine
          @set[name] model

      @on "change:#{mine}", @set[name]

    _hookHasMany: (name, rel) ->
      klass = getModel rel.hasMany
      theirs = rel.theirFk
      models = @get[name] = new klass.Collection

      klass.cache.on 'add', (model) =>
        models.add model if @id is model.get theirs

      models.add klass.cache.filter (model) =>
        @id is model.get theirs

    _hookHasManyVia: (name, rel) ->
      klass = getModel rel.hasMany
      viaKlass = getModel rel.via
      mine = rel.myViaFk
      theirs = rel.theirViaFk
      models = @get[name] = new klass.Collection
      via = models.via = new viaKlass.Collection
      klass.cache.on 'add', (model) =>
        models.add model if @id is model.get mine

      viaKlass.cache.on 'add', (model) =>
        if @id is model.get mine
          via.add model
          models.add klass.new {id: model.get theirs}

      via.on 'remove', (model) ->
        models.remove models.get model.get theirs

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

    _hookGroup: (name, rels) ->
      klass = getModel @relations[rels[0]].hasMany
      group = @get[name] = new klass.Collection
      for rel in rels
        group.add (rel = @get[rel]).models
        rel
          .on('add', (model) -> group.add model)
          .on 'remove', (model) -> group.remove model

    via: (rel, id) ->
      id = id.id if id?.id
      if group = @relations[rel].group
        for rel in group when via = @via rel, id
          return via
        return undefined
      @get[rel].via.find (model) =>
        id is model.get @relations[rel].theirViaFk

    change: ->
      @_previousId = @id
      @id = @_generateId()
      super arguments...

  class Model.Collection extends Backbone.Collection
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
        @[if options.add then 'add' else 'reset'] models
        success @, resp, options if success
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return @sync('read', this, options);

    save: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      options.success = (resp, status, xhr) =>
        @at(i).set attrs, xhr for attrs, i in @parse resp
        success @, resp, options if success
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return @sync('create', this, options);

    destroy: (options) ->
      options = if options then _.clone options else {}
      success = options.success
      options.success = (resp) ->
        for model in @models
          model.trigger 'destroy', model, model.collection, options
          success model, resp, options if success
        @trigger 'sync', @, resp, options
      options.error = Backbone.wrapError options.error, @, options
      return @sync 'delete', @, options

  Model

@BackboneOrm = @BackboneOrm() if Backbone?
