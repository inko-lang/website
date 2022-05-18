---
author: Yorick Peterse
title: >
  Static typing, pattern matching, and Inko's self-hosting compiler
date: 2020-06-11 23:00:00 UTC
---

It's been a while since our last Inko progress update. But worry not, we've been
hard at work on the self-hosting Inko compiler.

<!-- READ MORE -->

The last progress report is from November 2019, almost seven months ago. The
reason for the lack of updates is simple: we found the progress reports to be
less useful than anticipated. Working towards a self-hosting compiler takes a
long time, as past decisions may need to be re-evaluated as we go along. Such
decisions include what syntax to use for certain features, how the type system
should work, and more. This means that on a monthly basis there is less to talk
about, resulting in progress reports being a bit boring.

In the last couple of weeks, quite some changes have been made; changes that we
feel are worth discussing. We've also got some questions about the progress in
general. With that in mind, we decided to give you all an update about what we
have been up to since our last update.

## Table of contents
{:.no_toc}

* TOC
{:toc}

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/).

If you would like to engage with others interested in the development of Inko,
please join our community on [Matrix][matrix], [Reddit][reddit], or follow the
author of Inko on [Twitter](https://twitter.com/yorickpeterse). For more
information check out the [Community](/community) page.

## Windows CI now runs in VirtualBox

In the past we rented a VPS to run Windows tests on using GitLab CI. The costs
of the VPS were quite high, and using Windows containers using Docker proved
problematic. For example, updating the container alone could take hours; often
just getting stuck for no clear reason.

To resolve these issues we changed our CI setup for Windows. We now run Windows
tests in a VirtualBox VM, on a Mac Mini sponsored by
[MacStadium](https://www.macstadium.com/) (which we were already using for
running tests on macOS). This saves us just under €60 per month, and a lot of
headaches.

## Circular types are now supported

The Ruby compiler (and the code we have written so far for the self-hosting Inko
compiler) now supports circular types, such as the following:

```inko
object A {
  @thing: B

  def init(thing: B) {
    @thing = thing
  }
}

object B {
  @thing: A

  def init(thing: A) {
    @thing = thing
  }
}
```

The compiler supports this by performing multiple passes over the AST when
defining types, instead of only performing a single pass. This means that within
the same module, it no longer matters what order types are defined in.

Now that circular types are supported, forward trait declarations are no longer
necessary. This means the following is no longer valid:

```inko
trait A {}

object B {
  @thing: A

  def init(thing: A) {
    @thing = thing
  }
}

trait A {
  def foo
}
```

## Nil has been split up

The type `Nil` has been split up in `NilType` and `Nil`, with `Nil` being a
singleton instance of `NilType`; instead of `Nil` being both the object defined
using the `object` keyword and a singleton instance. This change is made so
that `Nil` becomes just another object instance, just like a `String` or
`Integer` instance.

## Modules are now first-class objects

Modules used to be emulated using objects defined in a "top-level" object. This
object was never garbage-collected, and was used solely for storing module
objects. This approach was a bit of a hack, and would complicate parts of the
self-hosting compiler; without bringing any benefits.

To resolve this, the VM now has first-class support for modules. This is mostly
an implementation detail, but makes it easier to maintain the VM and write a
compiler for Inko.

## Type parameters are no longer needed when re-opening objects

When re-opening a generic object, you no longer need to specify the names of the
object's type parameters. Instead, they are implicitly made available. This
means that you no longer need to write this:

```inko
object List!(T) {
  # ...
}

impl ToString for List!(T) {
  # ...
}
```

Instead, you can now write this:

```inko
object List!(T) {
  # ...
}

impl ToString for List {
  # ...
}
```

## Boolean.not has been removed in favour of Boolean.false? and Boolean.true?

Using the method `Boolean.not` could lead to rather confusing code, such as the
following:

```inko
def foo(value: Boolean) -> Boolean {
  value.not
}
```

Instead, you can now use `Boolean.false?` and `Boolean.true?`:

```inko
def foo(value: Boolean) -> Boolean {
  value.true?
}
```

The method `Boolean.false?` returns `True` if the receiver is `False`, while
`Boolean.true?` does the opposite.

## ByteArray is now in the prelude

The `ByteArray` type has been added to the prelude, removing the need for
importing it manually using `import std::byte_array::ByteArray`.

## Inko is now statically typed

Starting with the next release, Inko will be a statically typed language;
instead of being gradually typed. When creating Inko we decided to go with
gradual typing, with the hopes of it providing a bridge between the benefits of
dynamic typing and static typing. For example, dynamically typed languages allow
for rapid development and prototyping, while statically typed languages provide
better safety guarantees.

As we continued work on the self-hosting compiler, two problems presented
themselves:

1. Supporting gradual typing complicates the compiler, and may prevent certain
   optimisations.
1. Dynamically typed code does not play well with statically typed code.

An example of the first problem is keywords arguments. The VM has special
knowledge of keyword arguments, allowing you to use them when the type a message
is sent to is not known. This complicates the VM, adds overhead even when
sending messages without keyword arguments, and is not used in Inko's standard
library. To solve this, [we will change how keyword arguments are
implemented](https://gitlab.com/inko-lang/inko/-/issues/174). This
implementation requires that the compiler knows about all arguments available
for a message. As such, it will not work when sending messages to dynamically
typed values. As Inko's standard library makes little use of dynamic types, we
felt this trade-off is worth it.

Certain optimisations may also be difficult to implement when supporting dynamic
typing. For example, inlining is not possible when sending a message to a
dynamic type; at least not at compile-time.

Gradual typing also doesn't work well if most of the code you interact with is
statically typed, as is the case for Inko. This is because the compiler will
forbid you from using a dynamic type (e.g. as an argument) when instead a static
type (e.g. a `String`) is expected. To deal with this, every time you pass a
dynamic type somewhere you will have to cast it to the expected type. Take this
snippet for example:

```inko
import std::stdio::stdout

def say(message) {
  stdout.print(message)
}

say('Hello')
```

This code does not compile: the `message` argument is a dynamic type, but
`stdout.print` expects a type that implements the `ToString` trait. To make this
code compile, we would have to instead write the following:

```inko
import std::stdio::stdout
import std::conversion::ToString

def say(message) {
  stdout.print(message as ToString)
}

say('Hello')
```

This then brings the question: if we have to cast our types anyway, why not just
use static typing? We wouldn't have to cast our types as much, and get
compile-time safety.

With all this in mind, we have decided to make Inko a statically typed language.

Dynamic typing will be replaced with an `Any` trait, implemented by all objects.
This trait exists for the odd case where you don't know what type you are
dealing with at compile-time. Unlike a dynamic type, you can't send any messages
to an `Any` as it does not respond to any messages; except for those available
to the `Object` type. In other words, this compiles when using dynamic typing:

```inko
def example(message) {
  message.to_string
}
```

This does not compile when using the `Any` trait:

```inko
def example(message: Any) {
  message.to_string
}
```

This will not compile since neither `Any` nor `Object` (all types are an
instance of `Object`) respond to the message `to_string`.

This change also introduces some changes to the syntax, and how method return
types are inferred when left out. Method arguments must now specify either a
default value, or a type. This is no longer valid syntax:

```inko
def example(message) {
  # ...
}
```

Leaving out the return type no longer results in it being inferred as a dynamic
type. Instead, the return type is inferred as `Nil` and the method will always
return `Nil`. This means that this:

```inko
def example {

}
```

Is now the same as this:

```inko
def example -> Nil {
  Nil
}
```

Inferring the return type as `Nil` (and having the method return `Nil`) makes it
easier to write methods of which you want the return value to be ignored.

## Support for pattern matching

Inko will support a limited form of pattern matching. Originally added to
simplify the process of walking ASTs in the self-hosting compiler, there are
other cases where having pattern matching can be useful. The syntax is inspired
by that of Kotlin, and looks as follows:

```inko
def valid_number?(number: Integer) -> Boolean {
  match(number) {
    1..10 -> { True }
    else -> { False }
  }
}
```

Here we check if `number` falls in the range `1..10`, returning `True` if this
is the case. Pattern matching must be exhaustive, which we enforce by always
requiring the presence of an `else` branch. Thus, the following is not valid:

```inko
match(number) {
  1..10 -> { True }
  50 -> { True }
}
```

You can also specify multiple patterns, and the case is matched if any of the
patterns match:

```inko
def valid_number?(number: Integer) -> Boolean {
  match(number) {
    1, 2, 3, 4, 5 -> { True }
    5..8, 9..20 -> { True }
    else -> { False }
  }
}
```

Pattern matching expressions (as shown above) require that the patterns
specified (`1..10` for example) implement the trait `std::operators::Match`.
This allows types to decide how and when they match a value. In case of the
`Range` type, the implementation is as follows:

```inko
impl Match!(T) for Range {
  def =~(other: T) -> Boolean {
    cover?(other)
  }
}
```

We can also specify a "guard" in a pattern. If the pattern matches, the guard is
evaluated. Only if both the pattern and guard return True do we consider the
pattern as matched. For example:

```inko
def valid_token?(token: Token, current_line: Integer) -> Boolean {
  match(token.type) {
    'foo', 'bar', 'baz' when token.line == current_line -> { True }
    else -> { False }
  }
}
```

You can also bind the matched expression to a variable:

```inko
def valid_token?(token: Token, current_line: Integer) -> String {
  match(let type = token.type) {
    'foo', 'bar', 'baz' when token.line == current_line -> { type }
    else -> { 'unknown' }
  }
}
```

Pattern matching can also be used to perform a limited form of runtime type
checking. When combined with a binding, the binding type is set to the matched
type:

```inko
def visit(node: Node) {
  match(let matched = node) {
    as StringLiteral -> {
      # Here the type of "matched" is "StringLiteral"
    }
    as IntegerLiteral -> {
      # Here the type of "matched" is "IntegerLiteral"
    }
    else -> {
      # Here the type of "matched" is "Node"
    }
  }
}
```

The self-hosting compiler makes extensive use of this pattern when traversing
the AST, removing the need for using the visitor pattern.

## New Iterator methods

We've added several methods to the `Iterator` type: `all?`, `zip`, `join`, and
`reduce`.

`Iterator.all?` is used to test if all values in an `Iterator` match a
predicate:

```inko
Array.new(10, 20, 30).iter.all? do (value) { value.positive? } # => True
```

`Iterator.zip` is used to zip two iterators together:

```inko
let a = Array.new(10)
let b = Array.new(20)

a.iter.zip(b.iter).each do (pair) {
  pair.first  # => 10
  pair.second # => 20
}
```

`Iterator.join` is used to join the values in an `Iterator` together, producing
a `String`:

```inko
Array.new(10, 20, 30).iter.join(',') # => '10,20,30'
```

`Iterator.reduce` is used to reduce an `Iterator` to a single value:

```inko
Array
  .new(1, 2, 3)
  .iter
  .reduce(0) do (total, current) { total + current } # => 6
```

## Self-hosting compiler progress

Lots of progress has been made on Inko's self-hosting compiler. For the last
several months we have focused on the type-checker, which is coming around
nicely. A lot of Inko expressions can be type checked, though several important
ones (e.g. sending messages to objects) are not yet supported.

With the compiler we're taking our time to make sure we don't make decisions we
come to regret in the future. This slows down progress in the short term, but
will save us time in the future. We hope to finish the self-hosting compiler by
the end of 2020.

## Improvements to the website

We have moved several pages on the website around, so they are in a more
reasonable place. For example, the installation page is now located in the
manual. The "Documentation" link at the top has been replaced with a "Learn"
link that points straight to the manual, instead of pointing to a page telling
users where to find documentation.

## Plans for the coming months

In the coming months we will continue work on the type checker. Ideally we can
also start working on designing the Intermediate Representation(s) of the
compiler, used when optimising Inko code and generating bytecode. If you would
like to stay up to date, [please consider joining the growing community on
Matrix.org][matrix] or on [Reddit][reddit].

[matrix]: https://riot.im/app/#/room/#inko-lang:matrix.org
[reddit]: https://www.reddit.com/r/inko/
