_ = window?._ or require 'underscore'
Backbone = window?.Backbone or require 'backbone'

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

  model.set[name] = (next) ->
    return model if next is (prev = model.get[name])
    model.stopListening prev, {'change:id': changeId, destroy} if prev
    model.set(mine, next?.id).get[name] = next
    model.listenTo next, {'change:id': changeId, destroy} if next
    model

  model.listenTo ctor.cache(), 'add', (other) ->
    this.set[name] other if other.id and `other.id == model.get(mine)`

  model.on "change:#{mine}", (__, val) ->
    this.set[name] ctor.cache().get val

  changeId = (__, val) ->
    model.set mine, val

  destroy = ->
    model.set[name] null
    model.trigger 'destroy', model, model.collection if rel.romeo

  model.set[name] ctor.cache().get model.get mine

hasMany = (model, name, rel) ->
  ctor = getCtor rel.hasMany
  theirs = rel.theirFk
  models = model.get[name] = new ctor.Collection
  models.url = ->
    "#{_.result model, 'url'}#{_.result(rel, 'url') or "/#{name}"}"
  (models.filters = {})[theirs] = model

  models.listenTo ctor.cache(), "add change:#{theirs}", (other) ->
    this.add other if model.id and `model.id == other.get(theirs)`

  models.on "change:#{theirs}", (other) ->
    this.remove other

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

  via.listenTo viaCtor.cache(), "add change:#{mine}", (other) ->
    this.add other if model.id and `model.id == other.get(mine)`

  via.on "change:#{mine}", (other, val) ->
    this.remove other

  models.listenTo via, 'add', (other) ->
    this.add other if other = ctor.cache().get other.get theirs

  models.listenTo via, 'remove', (other) ->
    this.remove ctor.cache().get other.get theirs

  if model.id
    via.add viaCtor.cache().filter (other) ->
      `model.id == other.get(mine)`

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
