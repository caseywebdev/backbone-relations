BackboneOrm = require('../../lib/backbone-orm')()

module.exports = class Person extends BackboneOrm
  relations:
    iFriended:
      hasMany: -> Person
      via: -> require './friendship'
      myViaFk: 'friender'
      theirViaFk: 'friendee'
    friendedMe:
      hasMany: -> Person
      via: -> require './friendship'
      myViaFk: 'friendee'
      theirViaFk: 'friender'
    friends: ['friendedMe', 'iFriended']
    mom:
      hasOne: -> Person
      myFk: 'momId'
    dad:
      hasOne: -> Person
      myFk: 'dadId'
    momOf:
      hasMany: -> Person
      theirFk: 'momId'
    dadOf:
      hasMany: -> Person
      theirFk: 'dadId'
    children: ['momOf', 'dadOf']

class Person.Collection extends BackboneOrm.Collection
  model: Person

Person.cache = new Person.Collection
