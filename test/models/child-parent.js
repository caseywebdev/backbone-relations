var Backbone = require('backbone');
var Person = require('./person');

var ChildParent = module.exports = Backbone.Model.extend({
  relations: function () {
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
