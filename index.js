(function () {
  'use strict';

  var node = typeof window === 'undefined';

  var _ = node ? require('underscore') : window._;
  var Backbone = node ? require('backbone') : window.Backbone;

  var proto = Backbone.Model.prototype;
  var constructor = proto.constructor;
  var get = proto.get;
  var set = proto.set;

  Backbone.Model = Backbone.Model.extend({
    constructor: function (attrs, options) {
      if (this.relations) this.relations = this.relations();
      return constructor.call(this, attrs, options);
    },

    get: function (attr) {
      var rel = this.relations[attr];
      if (!rel) return get.call(this, attr);
      var instance = rel.instance;
      if (!instance || (rel.hasOne && instance.id !== this.get(rel.fk))) {
        if (rel.hasOne) {
          instance = rel.instance = new rel.hasOne();
          instance.set(instance.idAttribute, this.get(rel.fk));
        } else {
          instance = rel.instance = new rel.hasMany();
          instance.owner = this;
          instance.fk = rel.fk;
          var self = this;
          instance.url = function () {
            return _.result(self, 'url') + (rel.urlRoot || '/' + attr);
          };
          if (rel.via) {
            instance.via = this.get(rel.via);
            instance
              .add(instance.via.pluck(rel.get))
              .listenTo(instance.via, 'add', function (model) {
                this.add(model.get(rel.get));
              });
          } else {
            this.listenTo(instance, 'add', function (model) {
              if (model.get(rel.fk) !== this.id) model.set(rel.fk, this.id);
            });
          }
        }
      }
      return instance;
    },

    set: function (key, val, options) {
      if (key == null) return this;
      var attrs;
      if (typeof key === 'object') {
        attrs = key;
        options = val;
      } else {
        (attrs = {})[key] = val;
      }
      for (key in attrs) {
        var rel = this.relations[key];
        if (!rel) continue;
        val = attrs[key];
        delete attrs[key];
        if (rel.hasOne) {
          var instance = this.get(key);
          var model = val instanceof rel.hasOne ? val.attributes : val;
          instance.set(model, options);
          if (this.get(rel.fk) !== instance.id) attrs[rel.fk] = instance.id;
        } else {
          var models = val instanceof rel.hasMany ? val.models : val;
          this.get(key).update(models, options);
        }
      }
      return set.call(this, attrs, options);
    }
  });

  _.extend(Backbone.Collection.prototype, {model: Backbone.Model});
})();
