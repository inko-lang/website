---
title: Optional and Nil values
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

An optional value is a value that can be either `Nil`, or a specific type `T`.
Such a value's type is written as `?T`, where `T` is a regular type such as
`String` or `Person`.

In Inko, various operations will return an optional value. For example, for
`Array!(Integer)` the return type of `Array.[]` is `?Integer`, which means it
can be either `Nil` or an `Integer`. When sending a message to an optional value
or `Nil`, the returned value will be `Nil` itself. This drastically cuts down
the amount of conditionals necessary when dealing with optional values.

Let's say we have the following nested `Array`:

```inko
numbers = [
  [10, 20, 30],
  [40, 50, 60]
]
```

Given this `Array` we want to:

1. Get the `Array` at index 1.
1. Get the value of index 2 from this `Array`.

In most languages sending a message to `Nil` (or some other kind of nil-like
value) produces an error, requiring the use of conditionals. For example, in
Ruby we would write the following code to obtain our value:

```ruby
numbers = [
  [10, 20, 30],
  [40, 50, 60]
]

if numbers[1]
  numbers[1][2]
else
  nil
end
```

Here our code is still pretty simple, but if the number of optional values to
deal with increases this can quickly get out of hand.

In Inko we don't need to worry about any of this, meaning we can write the
following without encountering any errors:

```inko
numbers = [
  [10, 20, 30],
  [40, 50, 60]
]

numbers[1][2]
```

Some messages have their own implementation for `Nil`. For example, sending
`to_string` to `Nil` will result in an empty `String` being returned, instead of
`Nil`.

## Type compatibility

When dealing with an optional type `?T`, the compiler ensures that you can only
using messages that are supported by `T`. For example, the following is not
valid code as `String` does not respond to `foo`:

```inko
let people = ['alice']

people[0].foo
```

## Passing Nil

A `Nil` or `?T` can only be passed to another `?T`, but never to a `T`. This
prevents you from accidentally passing an option value to a method that does not
expect to receive any `Nil` values. This means the following is invalid:

```inko
import std::stdio::stdout

def greet(name: String) {
  stdout.print('Hello ' + name)
}

let people = ['alice']

greet(people[0])
```

This is invalid because `people[0]` might return `Nil`, and `greet` only accepts
a `String`. To deal with such cases you can use the `*` prefix operator, known
as the "unpack" operator. This operator tells the compiler that instead of
dealing with `?T` we are dealing with a `T`. Using this operator should always
be paired with a conditional, as no runtime checks are performed:

```inko
import std::stdio::stdout

def greet(name: String) {
  stdout.print('Hello ' + name)
}

let people = ['alice']
let person = people[0]

person.if_true {
  greet(*person)
}
```

Because of these rules, debugging the occurrence of a `Nil` value becomes easy,
as a `Nil` can never be passed somewhere implicitly (unless of course the
receiving argument accepts a `Nil`).
