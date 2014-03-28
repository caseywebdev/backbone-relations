var Model = require('./model');

var Person = module.exports = Model.extend({
  relations: {
    childJoins: {
      hasMany: 'child-parent',
      fk: 'parentId'
    },
    children: {
      hasMany: 'person',
      via: 'childJoins#child',
      fk: 'parentId'
    },
    parentJoins: {
      hasMany: 'child-parent',
      fk: 'childId'
    },
    parents: {
      hasMany: 'person',
      via: 'parentJoins#parent',
      fk: 'childId'
    },
    friendships: {
      hasMany: 'friendship',
      fk: 'friendeeId'
    },
    friends: {
      hasMany: 'person',
      via: 'friendships#friender',
      fk: 'friendeeId',
      url: 'this-is-a-test-url'
    },
    idol: {
      hasOne: 'person',
      fk: 'idolId'
    },
    fans: {
      hasMany: 'person',
      fk: 'idolId'
    },
    manager: {
      hasOne: 'person',
      fk: 'managerId'
    }
  }
});

Person.Collection = Model.Collection.extend({
  model: Person,
  url: '/people'
});
