BackboneRels = require('../../lib/backbone-rels')()

module.exports = class Friendship extends BackboneRels.Model
  compositeKey: ['frienderId', 'friendeeId']
  rels:
    friender:
      hasOne: -> require './person'
      myFk: 'frienderId'
    friendee:
      hasOne: -> require './person'
      myFk: 'friendeeId'

  @Collection: class extends BackboneRels.Collection
    url: '/friendships'

Friendship.setup()
