var Model = require('./model');

var Friendship = module.exports = Model.extend({
  relations: {
    friender: {
      hasOne: 'person',
      fk: 'frienderId'
    },
    friendee: {
      hasOne: 'person',
      fk: 'friendeeId'
    }
  }
});

Friendship.Collection = Model.Collection.extend({
  model: Friendship,
  url: '/friendships'
});
