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

    onChangeId = (__, val) ->
      model.set mine, val

    onDestroy = ->
      model.get[name] = undefined
      return model.trigger 'destroy', model, model.collection if rel.romeo
      model.set mine, null

    model.set[name] = (next) ->
      return model if next is (prev = model.get[name])
      model.stopListening prev, 'change:id': onChangeId, destroy: onDestroy if prev
      model.set(mine, next?.id).get[name] = next
      model.listenTo next, 'change:id': onChangeId, destroy: onDestroy if next
      model

    do onChangeMine = ->
      model.set[name] ctor.cache().get model.get mine

    ctor.cache().on 'add', (other) ->
      model.set[name] other if `other.id == model.get(mine)`

    model.on "change:#{mine}", onChangeMine

  hasMany = (model, name, rel) ->
    ctor = getCtor rel.hasMany
    theirs = rel.theirFk
    models = model.get[name] = new ctor.Collection
    models.url = ->
      "#{_.result model, 'url'}#{_.result(rel, 'url') or "/#{name}"}"
    (models.filters = {})[theirs] = model

    model.listenTo ctor.cache(), "add change:#{theirs}", (other) ->
      models.add other if model.id and `model.id == other.get(theirs)`

    model.listenTo models, "change:#{theirs}", (other, val) ->
      models.remove other unless `model.id == val`

    if model.id
      models.add ctor.cache().filter (other) ->
        `model.id == other.get(theirs)`

  hasManyVia = (model, name, rel) ->
    ctor = getCtor rel.hasMany
    viaCtor = getCtor rel.via
    mine = rel.myViaFk
    theirs = rel.theirViaFk
    models = model.get[name] = new ctor.Collection
    models.url = ->
      "#{_.result model, 'url'}#{_.result(rel, 'url') or "/#{name}"}"
    models.mine = theirs
    via = models.via = new viaCtor.Collection
    via.url = =>
      "#{_.result model, 'url'}#{_.result viaCtor.Collection::, 'url'}"
    (via.filters = {})[mine] = model
    attrs = {}

    model.listenTo viaCtor.cache(), 'add', (other) ->
      return unless model.id and `model.id == other.get(mine)` and
        otherModel = ctor.cache().get other.get theirs
      via.add other
      models.add otherModel

    model.listenTo ctor.cache(), 'add', (other) ->
      return unless (attrs[mine] = model.id) and (attrs[theirs] = other.id) and
        otherVia = via.get viaCtor::_generateId attrs
      via.add otherVia
      models.add other

    model.listenTo via, 'remove', (other) ->
      models.remove models.get other.get theirs

    model.listenTo models, 'remove', (other) ->
      attrs[mine] = model.id
      attrs[theirs] = other.id
      via.remove via.get viaCtor::_generateId attrs

    if model.id
      for other in viaCtor.cache().models
        continue unless `model.id == other.get(mine)` and
          otherModel = ctor.cache().get other.get theirs
        via.add other
        models.add otherModel

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
    initialize: (attrs, options) ->
      initialize.apply @, arguments
      @cache = options.cache if options?.cache?
      @constructor.cache().add @ if @cache
      hook @

    via: (rel, id) ->
      return unless id = id?.id or id
      viaCtor = getCtor @relations[rel].via
      (attrs = {})[@relations[rel].myViaFk] = @id
      attrs[@relations[rel].theirViaFk] = id
      @get[rel].via.get viaCtor::_generateId attrs

  # Create a `_generateId` method if backbone-composite-keys hasn't already
  # done so.
  Backbone.Model::_generateId or= (attrs = @attributes) ->
    attrs[@idAttribute]

  Backbone

bind Backbone if @Backbone
