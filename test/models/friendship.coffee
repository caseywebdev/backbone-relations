BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class Friendship extends BackboneOrm
  compositeKey: ['frienderId', 'friendeeId']
  relations:
    friender:
      hasOne: -> require './person'
      myFk: 'frienderId'
    friendee:
      hasOne: -> require './person'
      myFk: 'friendeeId'

class Friendship.Collection extends BackboneOrm.Collection
  class: Friendship
  url: '/friendships'

Friendship.cache = new Friendship.Collection
