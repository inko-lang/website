---
title: Methods, messages, and objects
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

In Inko we use objects for storing state, methods for defining sequences of
code to execute, and messages to run those sequences of code. While usually a
message maps to a method with the same name, this isn't always the case.

## Methods

Methods are defined using the `def` keyword:

```inko
def example {

}
```

Here we defined a method called "example". Methods can specify additional
information, such as: the arguments (and optionally their types), the return
type, and the throw type.

### Arguments

We can define arguments like so:

```inko
def add(number, add) {

}
```

Here we define two arguments: "number", and "add". The types of these arguments
are dynamic, if we want to use static types we can define the types as follows:

```inko
def add(number: Integer, add: Integer) {

}
```

Here we define the types of the arguments as `Integer`. We can also define
default values for arguments:

```inko
def add(number = 0, add = 0) {

}
```

When a default argument is given, the type of the argument is inferred based on
the value. If we want to specify a different type we can do so, as long as the
type is compatible with the default value:

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

By default, the return type of a method is dynamic. If we want to use a static
type, we can define one using `-> Type`, with `Type` being the return type. For
example:

```inko
def example -> Integer {
  10
}
```

Here the method is defined as returning an `Integer`. If a method has a static
return type, it _must_ return something that is compatible with that type. This
means code such as the following is not valid:

```inko
def example -> Integer {

}
```

This method is not valid, because its return type is `Integer` but the method
doesn't return anything.

## Messages

To execute a method, you must send a message to an object. Messages are
identifiers such as `foo` and `foo_bar`. An object will decide how to respond to
the message. In most cases the object will just run a method with the same name,
but sometimes it may decide to run a different method. The object that the
message is sent to is known as the "receiver".

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
message will be sent to `self`:

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
modify it (if necessary) without modifying the original version. We create
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

## Objects versus Classes

Objects are similar to classes found in other languages, but they are also quite
different. Classes typically have "static methods", also known as "class
methods". These are methods defined on a class and can be called without
creating an instance of the class. Classes also typically support inheritance.

Inko supports neither, and objects defined using the `object` keyword are just
objects like any other. As a result, we refer to them simply as "objects".
