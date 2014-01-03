var _ = require('underscore');
var BackboneRelations = require('../..');

var Model = module.exports = BackboneRelations.Model.extend({
  constructor: function () {
    this.constructor.relations();
    BackboneRelations.Model.apply(this, arguments);
  }
}, {
  relations: function () {
    if (this._relations) return this._relations;
    var relations = _.result(this.prototype, 'relations');
    if (!relations) return this._relations = {};
    relations = _.reduce(relations, function (rels, rel, key) {
      var Model = require('./' + (rel.hasOne || rel.hasMany));
      if (rel.hasOne) rel.hasOne = Model;
      if (rel.hasMany) rel.hasMany = Model.Collection;
      if (!rel.via) {
        var complement = Model.prototype.relations;
        var hasOne = !rel.hasOne;
        var fk = rel.fk;
        rel.reverse = _.reduce(complement, function (reverse, rel, key) {
          if (!rel.via && hasOne !== !rel.hasOne && fk === rel.fk) return key;
          return reverse;
        }, null);
      }
      rels[key] = rel;
      return rels;
    }, {});
    return this._relations = this.prototype.relations = relations;
  }
});

Model.Collection = BackboneRelations.Collection.extend({
  model: Model
});
