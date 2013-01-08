Backbone = require 'backbone'

module.exports =
class Person extends Backbone.Model
  cache: true
  relations:
    parents:
      hasMany: -> Person
      via: -> require './child-parent'
      myViaFk: 'childId'
      theirViaFk: 'parentId'
    children:
      hasMany: -> Person
      via: -> require './child-parent'
      myViaFk: 'parentId'
      theirViaFk: 'childId'
    friends:
      hasMany: -> Person
      via: -> require './friendship'
      myViaFk: 'frienderId'
      theirViaFk: 'friendeeId'
    idol:
      hasOne: -> Person
      myFk: 'idolId'
    fans:
      hasMany: -> Person
      theirFk: 'idolId'

class Person.Collection extends Backbone.Collection
  model: Person
  url: '/people'
