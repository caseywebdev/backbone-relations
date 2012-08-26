should = require('chai').should()
Person = require './models/person'

# Needs tests
describe 'People', ->
  mom = Person.new
    id: 1
  dad = Person.new
    id: 2
  childA = Person.new
    id: 3
    momId: mom.id
    dadId: dad.id
  childB = Person.new
    id: 4
    momId: mom.id
    dadId: dad.id
  childC = Person.new
    id: 5
    momId: mom.id
    dadId: dad.id

  childA.get.iFriended.add childB
  childB.get.iFriended.add childC

  it 'should set children', ->
    mom.get.children.models.should.include childA
    mom.get.children.models.should.include childB
    mom.get.children.models.should.include childC
    dad.get.children.models.should.include childA
    dad.get.children.models.should.include childB
    dad.get.children.models.should.include childC

  it 'should set mom and dad', ->
    childA.get.mom.should.equal mom
    childB.get.dad.should.equal dad

  it 'should set friends', ->
    childA.get.friends.models.should.include childB
    childB.get.friends.models.should.include childA
    childB.get.friends.models.should.include childC
    childC.get.friends.models.should.include childB
