Rels = require '../../lib/backbone-rels'

module.exports =
class ChildParent extends Rels.Model
  compositeKey: ['childId', 'parentId']
  rels:
    child:
      hasOne: -> require './person'
      myFk: 'childId'
      romeo: true
    parent:
      hasOne: -> require './person'
      myFk: 'parentId'
      romeo: true

class ChildParent.Collection extends Rels.Collection
  model: ChildParent
  url: '/child-parents'
