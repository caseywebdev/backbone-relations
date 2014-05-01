var BackboneRelations = require('../..');
var Person = require('./person');

exports.Model = BackboneRelations.Model.extend({
  relations: {
    friender: {
      hasOne: Person,
      fk: 'frienderId'
    },
    friendee: {
      hasOne: Person,
      fk: 'friendeeId'
    }
  }
});

exports.Collection = BackboneRelations.Collection.extend({
  model: exports.Model,
  url: '/friendships'
});
