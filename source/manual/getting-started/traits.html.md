---
title: Traits
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Traits are used for defining a common interface across types, and optionally
provide default method implementations for these types. Traits in Inko are a
restricted form of the original idea as described in the paper ["Traits:
Composable Units of Behaviour"][traits-paper]. Renaming methods in traits is not
possible, but might be supported in the feature.

## Defining traits

Traits are created using the keyword `trait`, followed by the name of the trait:

```inko
trait ToString {
  # ...
}
```

Traits can contain required methods, and default methods. A required method is a
method that an object must implement. A default method is copied over to the
implementing object, but an object is free to provide its own implementation
instead.

Required methods are defined just like regular methods, except they do not
contain a body:

```inko
trait ToString {
  def to_string -> String
}
```

This defines the trait `ToString`, with the required method `to_string`.

Default methods are defined like any other method:

```inko
trait ToString {
  def to_string -> String {
    'example'
  }
}
```

## Required traits

A trait can require other traits to be implemented. This is done as follows:

```inko
trait ToString: Foo, Bar {
  # ...
}
```

Here we define a `ToString` trait, which requires that implementing objects also
implement the traits `Foo` and `Bar`.

When a trait specifies one or more required traits, it can reference the methods
from that trait in its default methods:

```inko
trait ToString {
  def to_string -> String
}

trait ToQuotedString: ToString {
  def to_quoted_string -> String {
    '"' + to_string + '"'
  }
}
```

## Implementing traits

Traits are implemented in one of two ways:

1. When defining an object using the `object` keyword.
1. Using the `impl` keyword after an object has been defined.

### Implementing traits when defining objects

When defining an object, you can implement one or more traits right away:

```inko
trait ToString {
  def to_string -> to_string
}

object Person impl ToString {
  def to_string -> String {
    'Person'
  }
}
```

### Implementing traits separately

Implementing a trait separately is done using the syntax `impl TRAIT for
OBJECT`, like so:

```inko
trait ToString {
  def to_string -> to_string
}

object Person {

}

impl ToString for Person {
  def to_string -> String {
    'Person'
  }
}
```

## Type parameters

You can create generic traits by defining one or more type parameters, just like
you can do with objects:

```inko
trait ToArray!(T) {
  def to_array -> Array!(T)
}
```

When implementing a generic trait, you must specify what these type parameters
should map to:

```inko
trait ToArray!(T) {
  def to_array -> Array!(T)
}

impl ToArray!(Integer) for Integer {
  def to_array -> Array!(T) {
    [self]
  }
}
```

## Traits as argument and return types

Traits can be used for argument and return types:

```inko
trait ToString {
  def to_string -> String
}

def convert_to_string(value: ToString) -> ToString {
  value.to_string
}
```

When using a type that is a trait (e.g. as stored in a local variable), you are
limited to using the methods provided by the trait or the traits it requires:

```inko
trait ToString {
  def to_string -> String
}

def convert_to_string(value: ToString) -> ToString {
  value.to_string    # OK
  value.to_uppercase # not OK, since ToString.to_uppercase does not exist
}
```

[traits-paper]: http://scg.unibe.ch/archive/papers/Scha03aTraits.pdf
