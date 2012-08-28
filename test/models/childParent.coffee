BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class ChildParent extends BackboneOrm
  compositeKey: ['childId', 'parentId']
  relations:
    child:
      hasOne: -> require './person'
      myFk: 'childId'
    parent:
      hasOne: -> require './person'
      myFk: 'parentId'

class ChildParent.Collection extends BackboneOrm.Collection
  class: ChildParent
  url: '/child-parents'

ChildParent.cache = new ChildParent.Collection
