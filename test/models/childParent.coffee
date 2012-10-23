Backbone = require 'backbone'

module.exports =
class ChildParent extends Backbone.Model
  cacheAll: true
  idAttribute: ['childId', 'parentId']
  relations:
    child:
      hasOne: -> require './person'
      myFk: 'childId'
      romeo: true
    parent:
      hasOne: -> require './person'
      myFk: 'parentId'
      romeo: true

class ChildParent.Collection extends Backbone.Collection
  model: ChildParent
  url: '/child-parents'
