var BackboneRelations = require('../..');
var ChildParent = require('./child-parent');
var Friendship = require('./friendship');

exports.Model = BackboneRelations.Model.extend({
  relations: {
    childJoins: {
      hasMany: ChildParent,
      fk: 'parentId'
    },
    children: {
      hasMany: exports,
      via: 'childJoins#child',
      fk: 'parentId'
    },
    parentJoins: {
      hasMany: ChildParent,
      fk: 'childId'
    },
    parents: {
      hasMany: exports,
      via: 'parentJoins#parent',
      fk: 'childId',
      urlRoot: function () { return '/parents'; }
    },
    friendships: {
      hasMany: Friendship,
      fk: 'friendeeId'
    },
    friends: {
      hasMany: exports,
      via: 'friendships#friender',
      fk: 'friendeeId',
      url: 'this-is-a-test-url'
    },
    idol: {
      hasOne: exports,
      fk: 'idolId'
    },
    fans: {
      hasMany: exports,
      fk: 'idolId'
    },
    manager: {
      hasOne: exports,
      fk: 'managerId'
    }
  },

  urlRoot: '/people'
});

exports.Collection = BackboneRelations.Collection.extend({
  model: exports.Model,
  url: '/people'
});
