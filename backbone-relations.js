(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['underscore', 'backbone', 'herit'], factory);
  } else if (typeof exports !== 'undefined') {
    module.exports =
      factory(require('underscore'), require('backbone'), require('herit'));
  } else {
    root.BackboneRelations = factory(root._, root.Backbone, root.herit);
  }
})(this, function (_, Backbone, herit) {
  'use strict';

  var proto = Backbone.Model.prototype;
  var get = proto.get;
  var set = proto.set;

  var Relation = herit({
    constructor: function (options) {
      _.extend(this, options);
      if (this.via) {
        var split = this.via.split('#');
        this.via = split[0];
        this.viaKey = split[1] || this.key;
      }
    },

    get: function () { return this.instance(); },

    set: function (val, options) {
      options = _.extend({}, options, {add: true, merge: true, remove: true});
      this.instance().set(val || (this.hasOne ? {} : []), options);
    },

    resolve: function () {
      if (!this.via) return this.get();
      var via = this.owner.relations[this.via];
      var method = via.hasOne ? 'get' : 'pluck';
      var resolved = this.owner.resolve(this.via)[method](this.viaKey);
      if (this.hasOne) return resolved;
      return new this.hasMany(
        resolved[0] instanceof this.hasMany ?
        _.flatten(_.pluck(resolved, 'models')) :
        resolved
      );
    }
  });

  var HasOneRelation = herit(Relation, {
    instance: function () {
      if (this._instance) return this._instance;
      var Model = this.hasOne;
      var Collection = Backbone.Collection.extend({model: Model});
      var instance = this._instance = new Collection({});
      var owner = this.owner;
      var fk = this.fk;
      var reverse = this.reverse;
      if (fk) {
        var idAttr = Model.prototype.idAttribute;
        this.get().set(idAttr, owner.get(fk));
        instance.on('add change:' + idAttr, function (model, __, options) {
          owner.set(fk, model.id, options);
        });
        owner.on('change:' + fk, function (__, val, options) {
          if (this.get().id === val) return;
          var attrs = {};
          attrs[idAttr] =  val;
          instance.set(attrs, options);
        }, this);
      }
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

  var HasManyRelation = herit(Relation, {
    instance: function () {
      if (this._instance) return this._instance;
      var instance = this._instance = new this.hasMany();
      var owner = instance.owner = this.owner;
      instance.fk = this.fk;
      instance.urlRoot = this.urlRoot || '/' + this.key;
      instance.url = this.url || function () {
        return _.result(owner, 'url') + this.urlRoot;
      };
      var reverse = this.reverse;
      if (this.via) {
        instance.via = owner.get(this.via);
      } else if (reverse) {
        instance.on('add', function (model, __, options) {
          model.set(reverse, owner, options);
        });
      }
      return instance;
    }
  });

  var Model = Backbone.Model.extend({
    constructor: function () {
      this.constructor.resolveRelations();
      this.relations = _.reduce(this.relations, function (obj, options, key) {
        var ctor = options.hasOne ? HasOneRelation : HasManyRelation;
        obj[key] = new ctor(_.extend({}, options, {owner: this, key: key}));
        return obj;
      }, {}, this);
      return Backbone.Model.apply(this, arguments);
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

    resolve: function (key) {
      var relations = this.relations;
      if (!relations || !relations[key]) return;
      return relations[key].resolve(key);
    }
  }, {
    resolveRelations: function () {
      var relations = _.result(this.prototype, 'relations');
      if (!_.size(relations)) return;
      this.prototype.relations = relations;
      _.each(relations, function (rel) {
        if (_.isFunction(rel.hasOne || rel.hasMany)) return;
        if (rel.hasOne) rel.hasOne = rel.hasOne.Model;
        if (rel.hasMany) rel.hasMany = rel.hasMany.Collection;
        var fk = rel.fk;
        if (rel.via || !fk) return;
        var complement = rel.hasOne || rel.hasMany.prototype.model;
        if (!(complement.prototype instanceof Model)) return;
        complement.resolveRelations();
        var reverseRels = complement.prototype.relations;
        var hasOne = !rel.hasOne;
        rel.reverse = _.reduce(reverseRels, function (reverse, rel, key) {
          if (!rel.via && hasOne !== !rel.hasOne && fk === rel.fk) return key;
          return reverse;
        }, null);
      });
    }
  });

  return {Model: Model, Collection: Backbone.Collection.extend({model: Model})};
});
