BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class ChildParent extends BackboneOrm
  compositeKey: ['childId', 'parentId']
  urlRoot: '/child-parents'
  relations:
    child:
      hasOne: -> require './person'
      myFk: 'childId'
    parent:
      hasOne: -> require './person'
      myFk: 'parentId'

class ChildParent.Collection extends BackboneOrm.Collection
  class: ChildParent

ChildParent.cache = new ChildParent.Collection
