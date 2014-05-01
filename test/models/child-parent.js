var BackboneRelations = require('../..');
var Person = require('./person');

exports.Model = BackboneRelations.Model.extend({
  relations: {
    child: {
      hasOne: Person,
      fk: 'childId'
    },
    parent: {
      hasOne: Person,
      fk: 'parentId'
    }
  }
});

exports.Collection = BackboneRelations.Collection.extend({
  model: exports.Model,
  url: '/child-parents'
});
