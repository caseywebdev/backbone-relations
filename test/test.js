require('..');
require('chai').should();
var Person = require('./models/person');

var describe = global.describe;
var it = global.it;

describe('People', function () {
  var mom = new Person({id: 1});
  var dad = new Person({id: 2});
  var childA = new Person({id: 3});
  var childB = new Person({id: 4});
  var childC = new Person({id: 5});
  var rockstar = new Person({id: 6, name: 'Elvis'});

  mom.set({childJoins: [{child: childA}, {child: childB}]});
  dad.set('childJoins', [{child: childB}, {child: childC}]);

  childA.set('friendships', [{friender: childB}, {friender: childC}]);

  mom.set('idol', rockstar);
  rockstar.set('fans', childA);

  it('remembers the owner model', function () {
    var parent = new Person({id: 1});
    var child = new Person({
      id: 2,
      parentJoins: [{
        parent: {id: 1}
      }]
    });
    parent.set('childJoins', child.get('parentJoins').models);
    parent.get('children').should.have.length(1);
    parent.get('children').first().should.equal(child);
    parent.get('children').first().get('parents').first().should.equal(parent);
  });

  it('sets children', function () {
    mom.get('children').include(childA).should.be.ok;
    mom.get('children').include(childB).should.be.ok;
    dad.get('children').include(childB).should.be.ok;
    dad.get('children').include(childC).should.be.ok;
  });

  it('sets friends', function () {
    childA.get('friends').models.should.include(childB, childC);
  });

  it('always has a default hasOne', function () {
    (new Person()).get('idol').should.be.ok;
  });

  it('sets idol', function () {
    mom.get('idol').should.equal(rockstar);
    childA.get('idol').id.should.equal(rockstar.id);
  });

  it('sets fans', function () {
    rockstar.get('fans').include(childA).should.be.ok;
  });

  it('updates ids', function () {
    rockstar.set('id', 7);
    childA.get('idolId').should.equal(7);
    mom.get('idolId').should.equal(7);
  });

  it('ditchs old instances', function () {
    mom.set('idolId', 6);
    mom.get('idol').id.should.equal(6);
  });

  it('does not mutate objects passed to set', function () {
    var obj = {idol: rockstar};
    mom.set(obj);
    obj.should.have.property('idol');
  });
});
