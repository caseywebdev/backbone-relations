var Backbone = require('backbone');
var ChildParent = require('./child-parent');
var Friendship = require('./friendship');

var Person = module.exports = Backbone.Model.extend({
  relations: function () {
    return {
      childJoins: {
        hasMany: ChildParent.Collection,
        fk: 'childId'
      },
      children: {
        hasMany: Person.Collection,
        via: 'childJoins',
        fk: 'parentId'
      },
      parentJoins: {
        hasMany: ChildParent.Collection,
        fk: 'parentId'
      },
      parents: {
        hasMany: Person.Collection,
        via: 'parentJoins',
        fk: 'childId'
      },
      friendships: {
        hasMany: Friendship.Collection,
        fk: 'frienderId'
      },
      friends: {
        hasMany: Person.Collection,
        fk: 'friendeeId'
      },
      idol: {
        hasOne: Person,
        fk: 'idolId'
      },
      fans: {
        hasMany: Person.Collection,
        fk: 'idolId'
      }
    };
  }
});

Person.Collection = Backbone.Collection.extend({
  model: Person,
  url: '/people'
});
