Backbone = require 'backbone'

module.exports =
class Friendship extends Backbone.Model
  cacheAll: true
  idAttribute: ['frienderId', 'friendeeId']
  relations:
    friender:
      hasOne: -> require './person'
      myFk: 'frienderId'
      romeo: true
    friendee:
      hasOne: -> require './person'
      myFk: 'friendeeId'
      romeo: true

class Friendship.Collection extends Backbone.Collection
  model: Friendship
  url: '/friendships'
