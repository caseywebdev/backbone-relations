BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class Person extends BackboneOrm
  relations:
    parents:
      hasMany: -> Person
      via: -> require './childParent'
      myViaFk: 'childId'
      theirViaFk: 'parentId'
    children:
      hasMany: -> Person
      via: -> require './childParent'
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

class Person.Collection extends BackboneOrm.Collection
  model: Person
  url: '/people'

Person.cache = new Person.Collection
