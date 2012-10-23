_ = @_ or require 'underscore'

(module ? {}).exports = bind = (Backbone) ->

  getCtor = (val) ->
    if val instanceof Backbone.Model then val else val()

  hook = (model) ->

    # Check for the associations definition
    return unless model.relations

    # Create copies for modifying
    [get, model.get] = [model.get, -> get.apply model, arguments]
    [set, model.set] = [model.set, -> set.apply model, arguments]

    # Start hooking (that sounds scandalous)
    for name, rel of model.relations
      if rel.hasOne
        hasOne model, name, rel
      else if rel.via
        hasManyVia model, name, rel
      else
        hasMany model, name, rel

  hasOne = (model, name, rel) ->
    ctor = getCtor rel.hasOne
    mine = rel.myFk

    onChangeId = ->
      model.set mine, model.get[name].id

    onDestroy = ->
      delete model.get[name]
      if rel.romeo
        model.trigger 'destroy', model, model.collection
      else
        model.set mine, null

    model.set[name] = (next) ->
      prev = model.get[name]
      return if next is prev
      if prev
        prev.off 'change:id', onChangeId
        prev.off 'destroy', onDestroy
      model.get[name] = next
      model.set mine, next?.id
      if next
        next.on 'change:id', onChangeId
        next.on 'destroy', onDestroy

    (onChangeMine = ->
      model.set[name] ctor.cache().get model.get mine
    )()

    model.on "change:#{mine}", onChangeMine

    ctor.cache().on 'add', (other) ->
      model.set[name] other if other.id is model.get mine

  hasMany = (model, name, rel) ->
    ctor = getCtor rel.hasMany
    theirs = rel.theirFk
    models = model.get[name] = new ctor.Collection
    models.url = =>
      "#{_.result model, 'url'}#{_.result(rel, 'url') or "/#{name}"}"
    (models.filters = {})[theirs] = model

    ctor.cache().on "add change:#{theirs}", (other) ->
      models.add other if model.id is other.get theirs

    models.on "change:#{theirs}", (other) ->
      models.remove other

    models.add ctor.cache().filter (other) ->
      model.id is other.get theirs

  hasManyVia = (model, name, rel) ->
    ctor = getCtor rel.hasMany
    viaCtor = getCtor rel.via
    mine = rel.myViaFk
    theirs = rel.theirViaFk
    models = model.get[name] = new ctor.Collection
    models.url = =>
      "#{_.result model, 'url'}#{_.result(rel, 'url') or "/#{name}"}"
    models.mine = theirs
    via = models.via = new viaCtor.Collection
    via.url = =>
      "#{_.result model, 'url'}#{_.result viaCtor.Collection::, 'url'}"
    (via.filters = {})[mine] = model
    attrs = {}

    viaCtor.cache().on 'add', (other) ->
      via.add other if model.id is other.get mine

    via
      .on('add', (other) ->
        models.add ctor.new id: other.get theirs
      )
      .on 'remove', (other) ->
        models.remove models.get other.get theirs

    ctor.cache().on 'add', (other) ->
      attrs[mine] = model.id
      attrs[theirs] = other.id
      models.add other if via.get viaCtor::_generateId attrs

    models
      .on('add', (other) ->
        attrs[mine] = model.id
        attrs[theirs] = other.id
        via.add viaCtor.new attrs
      )
      .on 'remove', (other) ->
        attrs[mine] = model.id
        attrs[theirs] = other.id
        via.remove via.get viaCtor::_generateId attrs

    via.add viaCtor.cache().filter (other) ->
      model.id is other.get mine

  _.extend Backbone.Model,

    # Return the cache collection for this model
    cache: ->
      @_cache or= new @Collection

    # Search the cache first, then return a new model
    new: (attrs) ->
      model = @cache().get @::_generateId attrs
      model?.set(arguments...) or new @ arguments...

  # Save the original `initialize`
  initialize = Backbone.Model::initialize

  _.extend Backbone.Model::,
    initialize: ->
      initialize.apply @, arguments
      @constructor.cache().add @ if @cacheAll
      hook @

    via: (rel, id) ->
      return unless id = id?.id or id
      viaCtor = getCtor @relations[rel].via
      (attrs = {})[@relations[rel].myViaFk] = @id
      attrs[@relations[rel].theirViaFk] = id
      @get[rel].via.get viaCtor::_generateId attrs

  # Create a simple `_generateId` method if backbone-composite-keys hasn't
  # been required.
  Backbone.Model::_generateId or= (attrs = @attributes) ->
    attrs[@idAttribute]

  Backbone

bind Backbone if @Backbone
