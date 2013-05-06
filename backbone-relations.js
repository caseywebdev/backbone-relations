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
    this.key = key;
    this.owner = owner;
  };

  _.extend(Relation.prototype, Backbone.Events);

  var HasOneRelation = _.inherit(Relation, {
    get: function () {
      var instance = this.instance;
      if (instance && instance.id === this.owner.get(this.fk)) return instance;
      this.set(instance = new this.hasOne());
      return instance;
    },

    set: function (val, options) {
      if (val instanceof this.hasOne) {
        if (this.instance) this.stopListening(this.instance);
        this.instance = val;
        var owner = this.owner;
        var fk = this.fk;
        var idAttr = val.idAttribute;
        if (val.id) {
          owner.set(fk, val.id, options);
        } else {
          val.set(idAttr, owner.get(fk), options);
        }
        this.listenTo(val, 'change:' + idAttr, function (__, val, options) {
          owner.set(fk, val, options);
        });
      } else {
        this.get(this.key).set(val, options);
      }
    }
  });

  var HasManyRelation = _.inherit(Relation, {
    get: function () {
      var instance = this.instance;
      if (instance) {
        if (!this.via) return instance;
        var models = instance.via.pluck(this.via.split('#')[1] || this.key);
        return instance.set(
          models[0] instanceof this.hasMany ?
          _.flatten(_.pluck(models, 'models')) :
          models
        );
      }
      instance = this.instance = new this.hasMany();
      var urlRoot = instance.urlRoot = this.urlRoot;
      var owner = instance.owner = this.owner;
      var fk = instance.fk = this.fk;
      var key = this.key;
      instance.url = function () {
        return _.result(owner, 'url') + (urlRoot || '/' + key);
      };
      if (this.via) {
        instance.via = owner.get(this.via.split('#')[0]);
      } else {
        instance.each(function (model) { model.set(fk, owner.id); });
        owner.listenTo(instance, 'add', function (model) {
          model.set(fk, owner.id);
        });
        owner.on('change:' + owner.idAttribute, function (__, val) {
          instance.each(function (model) { model.set(fk, val); });
        });
      }
      return this.get();
    },

    set: function (val, options) {
      var models = val instanceof this.hasMany ? val.models : val;
      this.get(this.key).set(models, options);
    }
  });

  Backbone.Model = Backbone.Model.extend({
    constructor: function () {
      if (this.relations) {
        this.relations = _.reduce(this.relations(), function (o, options, key) {
          var ctor = options.hasOne ? HasOneRelation : HasManyRelation;
          o[key] = new ctor(this, key, options);
          return o;
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
