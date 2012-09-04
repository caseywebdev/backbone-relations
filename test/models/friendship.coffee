Rels = require '../../lib/backbone-rels'

module.exports =
class Friendship extends Rels.Model
  compositeKey: ['frienderId', 'friendeeId']
  rels:
    friender:
      hasOne: -> require './person'
      myFk: 'frienderId'
      romeo: true
    friendee:
      hasOne: -> require './person'
      myFk: 'friendeeId'
      romeo: true

class Friendship.Collection extends Rels.Collection
  model: Friendship
  url: '/friendships'
