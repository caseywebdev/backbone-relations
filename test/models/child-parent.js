var Backbone = require('backbone');

var ChildParent = module.exports = Backbone.Model.extend({
  relations: function () {
    var Person = require('./person');
    return {
      child: {
        hasOne: Person,
        fk: 'childId'
      },
      parent: {
        hasOne: Person,
        fk: 'parentId'
      }
    };
  }
});

ChildParent.Collection = Backbone.Collection.extend({
  model: ChildParent,
  url: '/child-parents'
});
