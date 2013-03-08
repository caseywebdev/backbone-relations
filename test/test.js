require('..');
require('chai').should();
var Person = require('./models/person');

var describe = global.describe;
var it = global.it;

describe('People', function () {
  var mom = new Person({id: 1, idolId: 6});
  var dad = new Person({id: 2});
  var childA = new Person({id: 3});
  var childB = new Person({id: 4});
  var childC = new Person({id: 5});
  var rockstar = new Person({id: 6, name: 'Elvis'});

  mom.get('children').add([childA, childB]);
  dad.set('children', [childB, childC]);

  childA.get('friends').add(childB);
  childB.set('friends', childC);

  childA.set('idol', rockstar);
  rockstar.set('fans', childA);

  it('should set children', function () {
    mom.get('children').include(childA).should.be.ok;
    mom.get('children').include(childB).should.be.ok;
    dad.get('children').include(childB).should.be.ok;
    dad.get('children').include(childC).should.be.ok;
  });

  it('should set friends', function () {
    childA.get('friends').include(childB).should.be.ok;
    childB.get('friends').include(childC).should.be.ok;
  });

  it('should set idol', function () {
    mom.get('idol').id.should.equal(6);
    childA.get('idol').id.should.equal(rockstar.id);
  });

  it('should set fans', function () {
    rockstar.get('fans').include(childA).should.be.ok;
  });
});
