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


  it('sets children', function () {
    mom.resolve('children').include(childA).should.be.ok;
    mom.resolve('children').include(childB).should.be.ok;
    dad.resolve('children').include(childB).should.be.ok;
    dad.resolve('children').include(childC).should.be.ok;
  });

  it('sets friends', function () {
    childA.resolve('friends').models.should.include(childB, childC);
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

  it('does not hold on to old reverse relations', function () {
    mom.resolve('children').models.should.include(childA)
      .and.not.include(childC);
    childA.resolve('parents').models.should.include(mom);
    childC.resolve('parents').models.should.not.include(mom);
    mom.get('childJoins').findWhere({childId: childA.id}).set('child', childC);
    mom.resolve('children').models.should.include(childC)
      .and.not.include(childA);
    childA.resolve('parents').models.should.not.include(mom);
    childC.resolve('parents').models.should.include(mom);
  });

  it('does not wipe out a model with null is passed', function () {
    var person = new Person();
    person.get('idol').should.not.be.falsey;
    person.set('idol', null);
    person.get('idol').should.not.be.falsey;
  });

  it('does not set a 1 element collection when null is passed', function () {
    var person = new Person();
    person.get('children').should.have.length(0);
    person.set('children', null);
    person.get('children').should.have.length(0);
  });

  it('allows url to be passed as an option', function () {
    (new Person()).get('friends').url.should.equal('this-is-a-test-url');
  });

  it('follows deeply nested relation setters', function () {
    (new Person({
      friends: [{
        idol: {
          manager: {
            name: 'Jerry'
          }
        }
      }]
    })).get('friends').first().get('idol').get('manager').get('name')
      .should.equal('Jerry');
  });

  it('proxies change events', function () {
    var a = new Person();
    var b = new Person();
    var c = new Person();
    a.set('idol', b);
    b.set('idol', a);
    b.set('manager', c);
    var calls = 0;
    b.once('change:manager', function (model) {
      model.should.equal(c);
      ++calls;
    });
    a.once('change:idol:manager', function (model) {
      model.should.equal(c);
      ++calls;
    });
    b.once('change:manager:name', function (model, val) {
      model.should.equal(c);
      val.should.equal('Billy');
      ++calls;
    });
    a.once('change:idol:manager:name', function (model, val) {
      model.should.equal(c);
      val.should.equal('Billy');
      ++calls;
    });
    c.set('name', 'Billy');
    calls.should.equal(4);
  });
});
