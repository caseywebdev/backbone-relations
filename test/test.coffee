should = require('chai').should()
Person = require './models/person'

# Needs tests
describe 'People', ->
  mom = new Person
    id: 1
    idolId: 6
  dad = new Person
    id: 2
  childA = new Person
    id: 3
  childB = new Person
    id: 4
  childC = new Person
    id: 5
  rockstar = new Person
    id: 6
    name: 'Elvis'

  mom.get.children.add childA
  mom.get.children.add childB
  dad.get.children.add childB
  dad.get.children.add childC

  childA.get.friends.add childB
  childB.get.friends.add childC

  childA.set idolId: 6
  childB.set.idol rockstar

  it 'should set children', ->
    mom.get.children.include(childA).should.be.true
    mom.get.children.include(childB).should.be.true
    dad.get.children.include(childB).should.be.true
    dad.get.children.include(childC).should.be.true

  it 'should set parents', ->
    childA.get.parents.include(mom).should.be.true
    childB.get.parents.include(mom).should.be.true
    childB.get.parents.include(dad).should.be.true
    childC.get.parents.include(dad).should.be.true

  it 'should set friends', ->
    childA.get.friends.include(childB).should.be.true
    childB.get.friends.include(childC).should.be.true

  it 'should set idol', ->
    mom.get.idol.should.equal rockstar
    childA.get.idol.should.equal rockstar
    childB.get.idol.get('name').should.equal 'Elvis'

  it 'should set fans', ->
    rockstar.get.fans.include(mom).should.be.true
    rockstar.get.fans.include(childA).should.be.true
    rockstar.get.fans.include(childB).should.be.true

  it 'should form correct urls', ->
    mom.get.children.url().should.equal '/people/1/children'
    mom.get.parents.url().should.equal '/people/1/parents'
    mom.get.children.via.url().should.equal '/people/1/child-parents'
    mom.get.parents.via.url().should.equal '/people/1/child-parents'
    mom.get.idol.url().should.equal '/people/6'
    rockstar.get.fans.url().should.equal '/people/6/fans'
    mom.get.children.via.at(0).url().should.equal '/child-parents/3-1'

  it 'should not repeat composite keys in collections', ->
    mom.get.children.via.length.should.equal 2
