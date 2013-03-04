var Backbone = require('backbone');
var Person = require('./person');

var Friendship = module.exports = Backbone.Model.extend({
  relations: function () {
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
