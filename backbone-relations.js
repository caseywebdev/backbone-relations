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
    get: function () { return this.instance(); },

    set: function (val, options) { this.instance().set(val, options); },

    resolveVia: function () {
      if (!this.via) return this.get();
      var split = this.via.split('#');
      var models = this.owner.via(split[0]).pluck(split[1] || this.key);
      return new this.hasMany(
        models[0] instanceof this.hasMany ?
        _.flatten(_.pluck(models, 'models')) :
        models
      );
    }
  });

  var HasOneRelation = _.inherit(Relation, {
    instance: function () {
      if (this._instance) return this._instance;
      var Model = this.hasOne;
      var Collection = Backbone.Collection.extend({model: Model});
      var owner = this.owner;
      var fk = this.fk;
      var reverse = this.reverse;
      var instance = this._instance = new Collection({id: owner.get(fk)});
      var idAttr = Model.prototype.idAttribute;
      instance.on('add change:' + idAttr, function (model, __, options) {
        owner.set(fk, model.id, options);
      });
      owner.on('change:' + fk, function (__, val, options) {
        if (instance.first().id !== val) {
          instance.set(new Model({id: val}), options);
        }
      });
      if (reverse) {
        instance.on({
          add: function (model, __, options) {
            model.get(reverse).add(owner, options);
          },
          remove: function (model, __, options) {
            model.get(reverse).remove(owner, options);
          }
        });
      }
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
      } else if (reverse) {
        instance.on('add', function (model, __, options) {
          model.set(reverse, owner, options);
        });
      }
      return instance;
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
      if (key == null) return this;
      var attrs;
      if (typeof key === 'object') {
        attrs = _.clone(key);
        options = val;
      } else {
        (attrs = {})[key] = val;
      }
      if (!this.relations) return set.call(this, key, val, options);
      for (key in attrs) {
        var rel = this.relations[key];
        if (rel) {
          val = attrs[key];
          delete attrs[key];
          rel.set(val, options);
        }
      }
      return set.call(this, attrs, options);
    },

    via: function (key) {
      var relations = this.relations;
      if (!relations || !relations[key]) return;
      return relations[key].resolveVia(key);
    }
  });

  _.extend(Backbone.Collection.prototype, {model: Backbone.Model});
})();
