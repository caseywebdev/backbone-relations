should = require('chai').should()
Person = require './models/person'

# Needs tests
describe 'People', ->
  mom = Person.new
    id: 1
    idolId: 6
  dad = Person.new
    id: 2
  childA = Person.new
    id: 3
  childB = Person.new
    id: 4
  childC = Person.new
    id: 5
  rockstar = Person.new
    id: 6

  mom.get.children.add childA
  mom.get.children.add childB
  dad.get.children.add childB
  dad.get.children.add childC

  childA.get.friends.add childB
  childB.get.friends.add childC

  childA.set idolId: 6
  childB.set.idol rockstar

  it 'should set children', ->
    mom.get.children.models.should.include childA
    mom.get.children.models.should.include childB
    dad.get.children.models.should.include childB
    dad.get.children.models.should.include childC

  it 'should set parents', ->
    childA.get.parents.should.include mom
    childB.get.parents.should.include mom
    childB.get.parents.should.include dad
    childC.get.parents.should.include dad

  it 'should set friends', ->
    childA.get.friends.models.should.include childB
    childB.get.friends.models.should.include childC

  it 'should set idol', ->
    mom.get.idol.should.equal rockstar
    childA.get.idol.should.equal rockstar
    childB.get.idol.should.equal rockstar

  it 'should set fans', ->
    rockstar.get.fans.models.should.include mom
    rockstar.get.fans.models.should.include childA
    rockstar.get.fans.models.should.include childB

  it 'should form correct urls', ->
    mom.get.children.url().should.equal '/people/1/children'
    mom.get.parents.url().should.equal '/people/1/parents'
    mom.get.children.via.url().should.equal '/people/1/child-parents'
    mom.get.parents.via.url().should.equal '/people/1/child-parents'
    mom.get.idol.url().should.equal '/people/6'
    rockstar.get.fans.url().should.equal '/people/6/fans'
    mom.get.children.via.at(0).url().should.equal '/child-parents/3-1'
