_ = @_ or require 'underscore'

(module? and module or {}).exports = @BackboneOrm =
(Backbone = @Backbone or require 'backbone') ->
  class BackboneOrm extends Backbone.Model
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

      # Define the relations object
      @rel = {}
      groups = []

      # Start building
      for name, rel of @relations
        if rel.group
          groups.push [name, rel]
        else if rel.hasOne
          @_hookHasOne name, rel
        else if rel.via
          @_hookHasManyVia name, rel
        else
          @_hookHasMany name, rel

      for group in groups
        @_hookGroup.apply @, group

    _hookHasOne: (name, rel) ->
      klass = if (k = rel.hasOne) instanceof BackboneOrm then k else k()
      mine = rel.myFk

      onIdChange = =>
        @set mine, @rel[name].id

      onDestroyModel = =>
        @trigger 'destroy', @

      (setModel = (next = klass.new id: @get mine) =>
        return if next.id isnt @get mine
        prev = @rel[name]
        return if next is prev
        if prev
          prev.off 'change:id', onIdChange
          prev.off 'destroy', onDestroyModel if rel.romeo
        @rel[name] = next
        next.on 'change:id', onIdChange
        next.on 'destroy', onDestroyModel if rel.romeo
      )()

      klass.cache.on 'add', setModel
      @on "change:#{mine}", setModel

    _hookHasMany: (name, rel) ->
      klass = if (k = rel.hasMany) instanceof BackboneOrm then k else k()
      theirs = rel.theirFk
      models = @rel[name] = new klass.Collection

      klass.cache.on 'add', (model) =>
        models.add model if @id is model.get theirs

      models.add klass.cache.filter (model) =>
        @id is model.get theirs

    _hookHasManyVia: (name, rel) ->
      klass = if (k = rel.hasMany) instanceof BackboneOrm then k else k()
      viaKlass = if (k = rel.via) instanceof BackboneOrm then k else k()
      mine = rel.myViaFk
      theirs = rel.theirViaFk
      models = @rel[name] = new klass.Collection
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

    _hookGroup: (name, group) ->
      klass =
        if (k = @relations[group[0]].hasMany) instanceof BackboneOrm then k else k()
      group = @rel[name] = new klass.Collection
      for rel of group
        group.add @rel[rel].models
        rel
          .on('add', (model) -> group.add model)
          .on 'remove', (model) -> group.remove model

    via: (rel, id) ->
      id = id.id if id.id?
      if group = @relations[rel].group
        for rel in group when via = @via rel, id
          return via
        return undefined
      @rel[rel].via.find (model) =>
        id is model.get @relations[rel].theirViaFk

    change: ->
      @_previousId = @id
      @id = @_generateId()
      super arguments...

  class BackboneOrm.Collection extends Backbone.Collection
    model: BackboneOrm

    _onModelEvent: (event, model, collection, options) ->
      if model and event is 'change' and model.id isnt model._previousId
        delete @_byId[model._previousId];
        @_byId[model.id] = model if model.id?
      super arguments...

    save: ->
      args = arguments
      @each (model) -> model.save args...

    fetch: ->
      args = arguments
      @each (model) -> model.fetch args...

    destroy: ->
      args = arguments
      @each (model) -> model.destroy args...

  BackboneOrm

@BackboneOrm = @BackboneOrm() if Backbone?
