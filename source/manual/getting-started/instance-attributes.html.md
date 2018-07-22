---
title: Instance attributes
---

Objects defined using the `object` keyword can define so called "instance
attributes", sometimes also called "instance variables". An "instance attribute"
is an attribute that can be set on an instance of an object. That might be a lot
to take in, so let's use an example. We want to define a "Person" object, and
store the name of the person. Every instance of this "Person" object has its own
name. To do so, we'd define our object like so:

```inko
object Person {
  def init(name: String) {
    let @name = name
  }
}
```

Instance attributes are defined using `let`, and the name of an instance
attribute starts with a `@`. In the above example we define an instance
attribute called `@name`, with the type being `String` (as inferred from the
`name` argument).

Instance attributes are private to the object, meaning you can not access them
directly from the outside. In other words, this is invalid:

```inko
person.@name
```

To expose these attributes, you must define a method that returns them:

```inko
object Person {
  def init(name: String) {
    let @name = name
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

Instance attributes can only be defined in the `init` method of an object, but
they can be reassigned (should they be defined as mutable) anywhere. This means
the following is invalid:

```inko
object Person {
  def name=(name: String) -> String {
    let @name = value
  }

  def name -> String {
    @name
  }
}
```

Instead you should use this:

```inko
object Person {
  def init(name: String) {
    let mut @name = name
  }

  def name=(name: String) -> String {
    @name = value
  }

  def name -> String {
    @name
  }
}
```
