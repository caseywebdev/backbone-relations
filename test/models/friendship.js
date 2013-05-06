var Backbone = require('backbone');

var Friendship = module.exports = Backbone.Model.extend({
  relations: function () {
    var Person = require('./person');
    return {
      friender: {
        hasOne: Person,
        fk: 'frienderId'
      },
      friendee: {
        hasOne: Person,
        fk: 'friendeeId'
      }
    };
  }
});

Friendship.Collection = Backbone.Collection.extend({
  model: Friendship,
  url: '/friendships'
});
