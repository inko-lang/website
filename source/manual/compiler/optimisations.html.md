---
title: Optimisations
---

## Table of contents
{:no_toc}

1. TOC
{:toc}

## Introduction

The compiler applies various optimisations to Inko code. The various
optimisations applied are described below.

## Converting keyword arguments into positional arguments

When using keywords arguments, the compiler will turn these into positional
arguments _if_ they are passed in the same order in which they are defined. This
removes the need for mapping keyword arguments to the positional arguments
during runtime. Take the following code for example:

```inko
def example(first: Integer, second: Integer) {}

example(first: 10, second: 20)
```

Because the keyword arguments are passed in the same order they are defined in,
the compiler is able to optimise this into the following:

```inko
def example(first: Integer, second: Integer) {}

example(10, 20)
```

If we were to change the order of the passed arguments, the compiler won't be
able to do this:


```inko
def example(first: Integer, second: Integer) {}

example(second: 10, first: 20) # This will not be optimised.
```

## HashMap literals

HashMap literals are just syntax sugar in Inko. For example, this:

```inko
%[ 'a': 10 ]
```

Is parsed into this:

```inko
HashMap.from_array(['a'], [10])
```

Because allocating two `Array` objects just to create a `HashMap` is not very
efficient, the compiler will optimise this into the following:

```inko
let hash_map = HashMap.new

hash_map['a'] = 10
```

Here the `hash_map` local variable is just used as an example, the compiler
won't actually use a local variable for this, instead it will directly store the
`HashMap` in a virtual machine register.

## Array literals

Similar to HashMap literals, Array literals are syntax sugar. For example, this:

```inko
[10, 20, 30]
```

Is parsed into this:

```inko
Array.new(10, 20, 30)
```

The compiler in turn will optimise literal occurrences of `Array.new` into a
specialised virtual machine instruction "SetArray". This instruction removes the
need for any method calls to create an `Array`.

## Sending "call" to a Block

Whenever the `call` message is sent to a `Block`, the compiler will replace the
method call with a "RunBlock" instruction. This is necessary as Inko uses the
`Block` type heavily, and calling methods every time they are executed would be
rather expensive.

This optimisation only occurs when sending `call` directory to a `Block`. If a
type is `Dynamic` then an actual method call will occur.

## Tail call elimination

The compiler uses tail call elimination to allow for tail recursive method
calls. This means that this:

```inko
def foo(number = 10) {
  number.zero?.if_true {
    return
  }

  foo(number - 1)
}
```

Is (more or less) compiled into the following:

```inko
def foo(number = 10) {
  start:
    number.zero?.if_true {
      return
    }

  tail:
    number = number - 1
    goto start
}
```

Tail call elimination only occurs if the last expression in a method is a call
to the method itself.
