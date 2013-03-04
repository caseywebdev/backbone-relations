(function () {
  'use strict';

  var node = typeof window === 'undefined';

  var _ = node ? require('underscore') : window._;
  var Backbone = node ? require('backbone') : window.Backbone;

  var proto = Backbone.Model.prototype;
  var initialize = proto.initialize;
  var get = proto.get;
  var set = proto.set;

  _.extend(proto, {
    initialize: function (attrs, options) {
      if (this.relations) this.relations = this.relations();
      return initialize.call(this, attrs, options);
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
          var self = this;
          instance.url = function () {
            return self.url() + (rel.urlRoot || '/' + attr);
          };
          if (rel.via) {
            var viaRel = this.relations[rel.via];
            instance.via = viaRel.hasMany.prototype.model.prototype;
            instance.localFk = rel.fk;
            instance.remote = this;
            instance.remoteFk = viaRel.fk;
          } else {
            (instance.where = {})[rel.fk] = this.id;
            instance.on('add', function (model) {
              if (model.get(rel.fk) !== self.id) model.set(rel.fk, self.id);
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
          var instance =
            val instanceof rel.hasOne ?
            rel.instance = val :
            this.get(key).set(val, options);
          if (this.get(rel.fk) !== instance.id) attrs[rel.fk] = instance.id;
        } else {
          if (val instanceof rel.hasMany) {
            rel.instance = val;
          } else {
            this.get(key).update(val, options);
          }
        }
      }
      return set.call(this, attrs, options);
    }
  });
})();
