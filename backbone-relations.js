(function () {
  'use strict';

  var node = typeof window === 'undefined';

  var _ = node ? require('underscore') : window._;
  if (node) require('underscore-inherit');
  var Backbone = node ? require('backbone') : window.Backbone;

  var proto = Backbone.Model.prototype;
  var constructor = proto.constructor;
  var get = proto.get;
  var set = proto.set;

  var Relation = function (owner, key, options) {
    _.extend(this, options);
    this.owner = owner;
    this.key = key;
  };

  _.extend(Relation.prototype, {
    set: function (val, options) {
      if (!options) options = {};
      if (!options.owner) options.owner = this.owner;
      var instance = this.instance();
      instance.set(val, options);
      var owner = options.owner;
      if (owner instanceof (this.hasOne || this.hasMany.prototype.model)) {
        var existing = instance.get(owner);
        if (existing && existing !== owner) {
          instance.remove(existing, options).add(owner, options);
        }
      }
    }
  });

  var HasOneRelation = _.inherit(Relation, {
    instance: function () {
      if (this._instance) return this._instance;
      var Model = this.hasOne;
      var Collection = Backbone.Collection.extend({model: Model});
      var instance = this._instance = new Collection();
      var idAttr = Model.prototype.idAttribute;
      instance.on('add change:' + idAttr, function (model, __, options) {
        this.owner.set(this.fk, model.id, options);
        if (this.reverse) model.get(this.reverse).add(this.owner, options);
      }, this);
      this.owner.on('change:' + this.fk, function (__, val, options) {
        if (!instance.get(val)) instance.set(new Model({id: val}), options);
      }, this);
      return instance;
    },

    get: function () { return this.instance().first(); }
  });

  var HasManyRelation = _.inherit(Relation, {
    instance: function () {
      if (this._instance) return this._instance;
      var instance = this._instance = new this.hasMany();
      var owner = instance.owner = this.owner;
      instance.fk = this.fk;
      instance.urlRoot = this.urlRoot || '/' + this.key;
      instance.url = function () {
        return _.result(owner, 'url') + this.urlRoot;
      };
      var reverse = this.reverse;
      if (this.via) {
        instance.via = owner.get(this.via.split('#')[0]);
      } else if (this.reverse) {
        instance.on('add', function (model, __, options) {
          model.set(reverse, owner, options);
        });
      }
      return instance;
    },

    get: function () {
      var instance = this.instance();
      if (!this.via) return instance;
      var models = instance.via.pluck(this.via.split('#')[1] || this.key);
      return instance.set(
        models[0] instanceof this.hasMany ?
        _.flatten(_.pluck(models, 'models')) :
        models
      );
    }
  });

  Backbone.Model = Backbone.Model.extend({
    constructor: function () {
      var relations = _.result(this, 'relations');
      if (relations) {
        this.relations = _.reduce(relations, function (obj, options, key) {
          var ctor = options.hasOne ? HasOneRelation : HasManyRelation;
          obj[key] = new ctor(this, key, options);
          return obj;
        }, {}, this);
      }
      return constructor.apply(this, arguments);
    },

    get: function (key) {
      if (!this.relations) return get.apply(this, arguments);
      var rel = this.relations[key];
      return rel ? rel.get(key) : get.call(this, key);
    },

    set: function (key, val, options) {
      if (!this.relations) return set.apply(this, arguments);
      if (key == null) return this;
      var attrs;
      if (typeof key === 'object') {
        attrs = _.clone(key);
        options = val;
      } else {
        (attrs = {})[key] = val;
      }
      for (key in attrs) {
        var rel = this.relations[key];
        if (rel) {
          val = attrs[key];
          delete attrs[key];
          rel.set(val, options);
        }
      }
      return set.call(this, attrs, options);
    }
  });

  _.extend(Backbone.Collection.prototype, {model: Backbone.Model});
})();
