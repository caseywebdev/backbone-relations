should = require('chai').should()
Backbone = require 'backbone'
require('../') Backbone
require('backbone-composite-keys') Backbone
ChildParent = require './models/child-parent'
Friendship = require './models/friendship'
Person = require './models/person'

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

  new ChildParent childId: childA.id, parentId: mom.id
  new ChildParent childId: childB.id, parentId: mom.id
  new ChildParent childId: childB.id, parentId: dad.id
  new ChildParent childId: childC.id, parentId: dad.id

  new Friendship frienderId: childA.id, friendeeId: childB.id
  new Friendship frienderId: childB.id, friendeeId: childC.id

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

  it 'should grab correct join models via...uh...`via`', ->
    mom.via('children', childA).id.should.equal '3-1'
    childA.via('parents', mom).id.should.equal '3-1'

  it 'should not cache new people with `{cache: false}`', ->
    person = new Person null, cache: false
    Person.cache().include(person).should.be.false
    person = new Person
    Person.cache().include(person).should.be.true
    person.destroy()
    Person.cache().include(person).should.be.false
