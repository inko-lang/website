---
title: Type inference
---
<!-- vale off -->

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Inko uses type inference, removing the need for manually adding type annotations
in a variety of places.

## Let bindings

When using the `let` keyword, the type of the variable is inferred based on the
value:

```inko
let number = 10
```

Here `number` is inferred as `Integer` because the return type of the expression
`10` is `Integer`.

If we wanted to we can still specify our own type, as long as the assigned value
is compatible with it:

```inko
let number: Integer = 10
```

## Method return types

Leaving out the return types for methods results in them being inferred as
`Nil`. When this happens, whatever value the method implicitly returns is
ignored. This means these two methods are the same (apart from their names):

```inko
# This will return Nil
def foo -> Nil {
  10
  Nil
}

# This will also return Nil
def bar {
  10
}
```

## Closures and lambdas

The arguments and return type of closures and lambdas are inferred according to
their usage. If the return type can't be inferred, it will default to `Nil`. If
the argument's can't be inferred, explicit type annotations are required.

To showcase these rules, consider the following example:

```inko
def example(block: do (Integer) -> Integer) {}

example do (number) {
  number
}
```

Here the compiler knows that `example` takes an argument of type `do (Integer)
-> Integer`. As a result, it is able to infer that `do (number) { number }` is
of the same type. This means that the following code would not compile, since
`number` (an `Integer`) does not respond to `foo`:

```inko
def example(block: do (Integer) -> Integer) {}

example do (number) {
  number.foo
}
```

Here the compiler is not able to infer our types, because the closure is defined
before it is being used:

```inko
def example(block: do (Integer) -> Integer) {}

let closure = do (number) {
  number
}

example(closure)
```

Running this code will result in a compile-time error. To solve this, explicit
type annotations are required:

```inko
def example(block: do (Integer) -> Integer) {}

let closure = do (number: Integer) {
  number
}

example(closure)
```

We do not need to annotate the return type, as the compiler can infer this for
us.
