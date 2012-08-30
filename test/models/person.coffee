Rels = require '../../lib/backbone-rels'

module.exports =
class Person extends Rels.Model
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

class Person.Collection extends Rels.Collection
  model: Person
  url: '/people'
