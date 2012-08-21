_ = require 'underscore'
Backbone = @Backbone or require 'backbone'

(module or {}).exports = @BackboneOrm = class BackboneOrm extends Backbone.Model
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

BackboneOrm.sync = (method, model, options) ->
  table = model.table
  queries = []
  values = []
  indexes = options.compositeKey or model.compositeKey or ['id']
  indexes = _.reduce indexes, (indexes, index) ->
    indexes[index] = model.get index
    indexes
  , {}

  switch method
    when 'read'
      where = sqlr.colsAreVals ids, values, table, ' AND '
      queries.push
        text: """
          SELECT *
          FROM "#{table}"
          WHERE #{where}
          LIMIT 1
        """
        values: values
      break
    when 'create', 'update'
      if Object.keys(model.attributes).length
        set = sqlr.colsToVals model.attributes, values
        where = sqlr.colsAreVals indexes, values, table, ' AND '
        queries.push
          text: """
            UPDATE "#{table}"
            SET #{set}
            WHERE #{where}
            RETURNING *;
          """
          values: values
        values = []
        cols = sqlr.columns model.attributes
        vals = sqlr.values model.attributes, values
        where = sqlr.colsAreVals indexes, values, table, ' AND '
        queries.push
          text: """
            INSERT INTO "#{table}" (#{cols}) (
              SELECT #{vals}
              WHERE NOT EXISTS (
                SELECT 1
                FROM "#{table}"
                WHERE #{where}
              )
            )
            RETURNING *;
          """
          values: values
      else
        queries.push
          text: """
            INSERT INTO "#{table}"
            DEFAULT VALUES
            RETURNING *;
          """
          values: []
      break
    when 'delete'
      where = sqlr.colsAreVals indexes, values, table, ' AND '
      queries.push
        text: """
          DELETE FROM "#{table}"
          WHERE #{where}
        """
        values: values

  n = 0
  m = queries.length
  _.each queries, (query) ->

    # Be sure to name the prepared statement so it can be reused
    query.name = query.text
    app.db.query query, (err, result) ->
      return options.error err if err
      model.set result.rows[0]
      options.success() if ++n is m

sqlr =
  columns: (data, table) ->
    _.map(data, (col, i) ->
      col = i unless table or _.isArray data
      sqlr.column col, table
    ).join ', '

  column: (col, table) ->
    "#{if table then "\"#{table}\"." else ''}\"#{col}\""

  values: (data, values) ->
    _.reduce data, (text, val) ->
      values.push val
      n = values.length
      text += if text then ", $#{n}" else "$#{n}"
    , ''

  colsAreVals: (data, values, table, delimiter = ', ') ->
    _.map(data, (val, col) ->
      sqlr.binaryGet sqlr.column(col, table), val, values
    ).join delimiter

  colsToVals: (data, values, table) ->
    _.map(data, (val, col) ->
      sqlr.binarySet sqlr.column(col, table), val, values
    ).join ', '

  binaryGet: (left, right, values, operator = '=') ->
    l = left
    r = '?'
    o = operator
    unless right?
      switch operator
        when '=', '!='
          r = 'NULL'
          o = 'IS'
          o += ' NOT' if operator is '!='
        else
          r = 0
    if r isnt 'NULL'
      values.push right
      r = "$#{values.length}"
    "#{l} #{o} #{r}"

  binarySet: (left, right, values) ->
    values.push right
    right = "$#{values.length}"
    "#{left} = #{right}"

