var Model = require('./model');

var ChildParent = module.exports = Model.extend({
  relations: {
    child: {
      hasOne: 'person',
      fk: 'childId'
    },
    parent: {
      hasOne: 'person',
      fk: 'parentId'
    }
  }
});

ChildParent.Collection = Model.Collection.extend({
  model: ChildParent,
  url: '/child-parents'
});
