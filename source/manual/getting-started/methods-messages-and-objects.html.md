---
title: Methods, messages, and objects
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

In Inko we use objects for storing state, methods for defining sequences of
code to execute, and messages to run those sequences of code. In most cases a
message maps to a method with the same name, but this isn't always the case.

## Methods

Methods are defined using the `def` keyword:

```inko
def example {

}
```

Here we defined a method called "example". Methods can specify extra
information, such as: the arguments, the return type, and the throw type.

### Arguments

We can define arguments like so:

```inko
def add(number: Integer, add: Integer) {

}
```

Here we define two arguments: "number", and "add"; both of type "Integer". We
can also define default values for arguments:

```inko
def add(number = 0, add = 0) {

}
```

When a default argument is given, the argument's type is inferred based on the
value. If we want to specify a different type we can do so, as long as the type
is compatible with the default value:

```inko
def add(number: Numeric = 0, add: Numeric = 0) {

}
```

Here, despite the default argument value's type being `Integer`, we specify the
type to be `Numeric`. If the given type is not compatible with the default
argument's type, the compiler will produce an error.

By default, arguments can not be reassigned. To allow this, you can define the
arguments as mutable:

```inko
def example(mut number = 10) {
  number = 20
}
```

### Throw type

If a method throws an error, it must specify the error type in the method
signature. Methods can also only throw one error. We do so by adding `!! Error`
to the method signature, with `Error` being the error type. For example:

```inko
def example !! Integer {

}
```

Here the method "example" is defined as throwing an `Integer`. If a method
states it throws an error it must also actually throw an error, but this will be
covered in a separate guide. If no throw type is given, a method can't throw an
error.

### Return type

A method's return type can be omitted. In this case, the return type is inferred
as `Nil` and any values returned are ignored. You can specify your own type as
follows:

```inko
def example -> Integer {
  10
}
```

Here the method is defined as returning an `Integer`. The values returned by a
method must be compatible with its return type. This means code such as the
following is not valid:

```inko
def example -> Integer {

}
```

This method is not valid, because its return type is `Integer` but the method
doesn't return anything.

## Messages

To call a method, you must send a message to an object. Messages are identifiers
such as `foo` and `foo_bar`. An object will decide how to respond to the
message. In most cases the object will just run a method with the same name, but
sometimes it may decide to run a different method. The object that the message
is sent to is known as the "receiver".

For sending message Inko uses the syntax `receiver.message`, with `receiver`
being the object the message is sent to, and `message` being the message name.
When sending a message you can pass arguments like so:

```inko
message(argument1, argument2, argument3)
```

You can leave out the parenthesis as well:

```inko
message argument1, argument2, argument3
```

Sending a message to a specific object is done like so:

```inko
10.to_string # => '10'
```

When sending a message, you can leave out an explicit receiver. In this case the
message is sent to `self`:

```inko
# Both of these examples result in exactly the same code being run.
message_name

self.message_name
```


`self` refers to the object the current block of code operates on. In a method
`self` is the object the method was invoked on:

```inko
object Person {
  def example {
    # This will return the instance of Person that "example" was invoked on.
    self
  }
}
```

In a module it's the module itself:

```inko
# This will return the current module.
self
```

Closures capture `self` from their enclosing scope:

```inko
object Person {
  def example {
    do {
      # This will return "Person" since the closure captures it.
      self
    }
  }
}
```

Inside a lambda, `self` refers to the module the lambda was defined in:

```inko
lambda {
  # This will return the module this lambda is defined in.
  self
}
```

## Objects

Objects are created using the `object` keyword, and require you to give your
object name:

```inko
object Person {

}
```

Here we define an object called "Person", which we can then refer to using a
constant with the same name:

```inko
object Person {

}

Person # This will return our Person object.
```

Instead of using an object directly, we typically create a new "instance" of the
object and then use that. An "instance" is a copy of the object, allowing you to
change it (if necessary) without modifying the original version. We create
instances of objects by sending `new` to the object:

```inko
object Person {

}

Person.new
```

Sending `new` to an object will result in a new copy being created, followed by
sending `init` to this copy. Any arguments passed to `new` are also passed to
`init`:

```inko
object Person {
  def init(number: Integer) {
    number # => 10
  }
}

Person.new(10)
```

Objects also allow you to define static methods. You do not need an instance of
the object to call these methods:

```inko
object Person {
  static def anonymous -> Person {
    new('Anonymous')
  }

  def init(name: String) {
    # ...
  }
}

Person.anonymous
```

It's considered good practise for static methods to return instances of the
objects they are defined on. If you have a static method that returns a
different type, it's recommended to turn this into a module method instead (or a
static method on the object that is returned).

## Objects versus Classes

Objects in Inko are similar to classes found in other languages. Unlike other
languages, Inko does not support class inheritance; instead relying on
composition using traits. Types created using the `object` keyword are objects
themselves, and you can send messages to them. To reinforce that objects are not
just blueprints you can only use to create an instance, we use the term "object"
instead of "class".
