---
title: Instance attributes
---
<!-- vale off -->

Objects defined using the `object` keyword can define so called "instance
attributes", sometimes also called "instance variables". An "instance attribute"
is an attribute that can be set on an instance of an object. That might be a lot
to take in, so let's use an example. We want to define a "Person" object, and
store the name of the person. Every instance of this "Person" object has its own
name. To do so, we'd define our object like so:

```inko
object Person {
  @name: String

  def init(name: String) {
    @name = name
  }
}
```

Instance attributes are defined in the object body, and the name of an instance
attribute starts with a `@`. In the above example we define an instance
attribute called `@name`, with the type being `String`. All instance attributes
of an object must be set in its `init` method.

Instance attributes are private to the object, meaning you can not access them
directly from the outside. In other words, this is invalid:

```inko
person.@name
```

To expose these attributes, you must define a method that returns them:

```inko
object Person {
  @name: String

  def init(name: String) {
    @name = name
  }

  def name -> String {
    @name
  }
}
```

You can then access the value by sending `name` to a `Person` instance:

```inko
Person.new('Alice').name # => 'Alice'
```
