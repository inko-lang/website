---
title: Type inference
---
<!-- vale off -->

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Inko employs type inference to remove the need for manually adding type
annotations in a variety of places. Because Inko is a gradually typed language,
in certain cases a type will be inferred as `Dynamic` instead of it being
inferred based on a value assigned or returned.

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
let number: Dynamic = 10
```

## Method arguments and return values

Method arguments and return values are inferred as `Dynamic` by default to allow
for gradual typing:

```inko
def example(number) {
  number
}
```

Here the `number` argument is of type `Dynamic`, and so is the return value of
the `example` method. We can specify a custom type as follows:

```inko
def example(number: Integer) -> Integer {
  number
}
```

## Closures and lambdas

When defining a closure or lambda, the following rules apply:

1. Arguments are inferred as `Dynamic` by default.
1. The return type is inferred based on the last expression returned by the
   closure or lambda.
1. If a closure or lambda is passed _directly_ as an argument, and the
   argument's type is compatible, the closure or lambda is inferred according to
   the argument it is passed to.

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

If we try to run this code, we are presented with the following compiler error:

```
ERROR: Expected a value of type "do (Integer) -> Integer" instead of "do (Dynamic) -> Dynamic"
 --> /tmp/test.inko on line 7, column 9
   |
 7 | example(closure)
   |         ^
```

To solve this, manual type annotations are required:

```inko
def example(block: do (Integer) -> Integer) {}

let closure = do (number: Integer) {
  number
}

example(closure)
```

We do not need to annotate the return type, as the compiler can infer this for
us.
