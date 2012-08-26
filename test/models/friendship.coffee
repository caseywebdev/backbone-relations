BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class Friendship extends BackboneOrm
  relations:
    friender:
      hasOne: -> require './person'
      myFk: 'frienderId'
    friendee:
      hasOne: -> require './person'
      myFk: 'friendeeId'

class Friendship.Collection extends BackboneOrm.Collection
  class: Friendship

Friendship.cache = new Friendship.Collection
