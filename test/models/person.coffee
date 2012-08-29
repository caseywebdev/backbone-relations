BackboneRels = require('../../lib/backbone-rels')()

module.exports = class Person extends BackboneRels.Model
  rels:
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

  @Collection: class extends BackboneRels.Collection
    url: '/people'

Person.setup()
