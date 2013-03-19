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
      var rel = this.relations && this.relations[attr];
      if (!rel) return get.call(this, attr);
      var instance = rel.instance;
      if (!instance || (rel.hasOne && instance.id !== this.get(rel.fk))) {
        if (rel.hasOne) {
          this._setOne(rel, instance = new rel.hasOne());
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
          } else {
            instance.each(function (model) { model.set(rel.fk, self.id); });
            this.listenTo(instance, 'add', function (model) {
              model.set(rel.fk, this.id);
            });
            this.on('change:' + this.idAttribute, function (__, val) {
              instance.each(function (model) { model.set(rel.fk, val); });
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
      if (this.relations) {
        for (key in attrs) {
          var rel = this.relations[key];
          if (!rel) continue;
          val = attrs[key];
          delete attrs[key];
          if (rel.hasOne) {
            if (val instanceof rel.hasOne) {
              this._setOne(rel, val, options);
            } else {
              this.get(key).set(val, options);
            }
          } else {
            var models = val instanceof rel.hasMany ? val.models : val;
            this.get(key).update(models, options);
          }
        }
      }
      return set.call(this, attrs, options);
    },

    _setOne: function (rel, instance, options) {
      if (rel.listener) this.stopListening(null, null, rel.listener);
      rel.instance = instance;
      var idAttr = instance.idAttribute;
      if (instance.id) {
        this.set(rel.fk, instance.id, options);
      } else {
        instance.set(idAttr, this.get(rel.fk), options);
      }
      rel.listener = function (__, val, options) {
        this.set(rel.fk, val, options);
      };
      this.listenTo(instance, 'change:' + idAttr, rel.listener);
    }
  });

  _.extend(Backbone.Collection.prototype, {model: Backbone.Model});
})();
