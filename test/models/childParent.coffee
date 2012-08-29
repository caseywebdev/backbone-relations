BackboneRels = require('../../lib/backbone-rels')()

module.exports = class ChildParent extends BackboneRels.Model
  compositeKey: ['childId', 'parentId']
  rels:
    child:
      hasOne: -> require './person'
      myFk: 'childId'
    parent:
      hasOne: -> require './person'
      myFk: 'parentId'

  @Collection: class extends BackboneRels.Collection
    url: '/child-parents'

ChildParent.setup()
