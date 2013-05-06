var Backbone = require('backbone');

var Person = module.exports = Backbone.Model.extend({
  relations: function () {
    var ChildParent = require('./child-parent');
    var Friendship = require('./friendship');
    return {
      childJoins: {
        hasMany: ChildParent.Collection,
        fk: 'parentId'
      },
      children: {
        hasMany: Person.Collection,
        via: 'childJoins#child',
        fk: 'parentId'
      },
      parentJoins: {
        hasMany: ChildParent.Collection,
        fk: 'childId'
      },
      parents: {
        hasMany: Person.Collection,
        via: 'parentJoins#parent',
        fk: 'childId'
      },
      friendships: {
        hasMany: Friendship.Collection,
        fk: 'friendeeId'
      },
      friends: {
        hasMany: Person.Collection,
        via: 'friendships#friender',
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
