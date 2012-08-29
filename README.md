[![Build Status](https://secure.travis-ci.org/caseywebdev/backbone-rels.png)](http://travis-ci.org/caseywebdev/backbone-rels)

backbone-rels
===

Backbone one-to-one, one-to-many, and many-to-many relationships for the browser and nodejs.

Install
-------

```bash
npm install backbone-rels
```

Use
---

Check out the test models for examples. Basically...

```coffee
class MyModel extends BackboneRels.Model
  rels:
    modelA:
      hasOne: ModelA
      myFk: 'modelAId'
    modelBs:
      hasMany: ModelB
      theirFk: 'myModelId'
    modelCs:
      hasMany: ModelC
      via: JoinModel
      myViaFk: 'myModelId'
      theirViaFk: 'modelCId'
  @Collection: class extends BackboneRels.Collection
    url: '/my-models'
MyModel.setup()
```

Will give you...

```
myModel = MyModel.new()
modelA = ModelA.new()
myModel.set.modelA modelA
myModel.get 'modelAId' # modelA.id
myModel.get.modelA # modelA
myModel.get.modelBs # ModelB.Collection
myModel.get.modelCs # ModelC.Collection
myModel.get.modelCs.via # JoinModel.Collection
myModel.get.modelCs.add ModelC.new()
myModel.get.modelCs.length # 1
myModel.get.modelCs.via.length # 1
```

Test
----

```bash
make test
```

Licence
-------

Copyright (C) 2012 Casey Foster <casey@caseywebdev.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
