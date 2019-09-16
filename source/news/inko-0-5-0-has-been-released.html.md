---
title: Inko 0.5.0 has been released
date: 2019-09-16 18:17:15 UTC
description: Inko 0.5.0 has been released
---

Inko 0.5.0 has been released. This release includes syntax changes, a module for
parsing Inko source code into an AST, support for random number generation, and
much more.

<!-- READ MORE -->

## Noteworthy changes in 0.5.0
{:.no_toc}

* TOC
{:toc}

The full list of changes is found in the [CHANGELOG][changelog]. If you would
like to support the continued development if Inko, please [donate €5 per month
(or more) on Open Collective][open-collective].

## Syntax changes

In 0.5.0, the syntax of Inko has changed quite a bit. We wrote about this in the
progress reports for [July 2019][july-2019] and [August 2019][aug-2019]. We made
these changes to simplify the language, and to make it easier to write a parser
for Inko in Inko itself.

### Implementing traits when defining objects

The syntax that allowed you to implement traits when defining an object has been
removed. This means that instead of this:

```inko
# This is no longer valid.
object Person impl ToString {
  # ...

  def to_string -> String {
    'An example'
  }
}
```

You will now have to implement every trait using a separate `impl` expression:

```inko
object Person {
  # ...
}

impl ToString for Person {
  def to_string -> String {
    'An example'
  }
}
```

### Removal of compiler options

Modules could set compiler options using the syntax `![option: value]`.  Since
these were only used internally, they have been removed. The compiler now sets
these options automatically for the modules requiring these options.

### Nested objects and traits

You can no longer define an object or trait inside another object or trait.
Instead, these types have to be defined at the top-level of a module. This means
that this is no longer valid:

```inko
object A {
  object B {
    # ...
  }
}
```

### New syntax for the not-Nil operator

To convert a type from `?T` to `T`, Inko has the "not-Nil" operator. Before
version 0.5.0, this was the prefix operator `*`:

```inko
def something -> ?Integer {
  Nil
}

*something # => T
```

In 0.5.0 the syntax has been changed to a postfix `!` operator, making it easier
to parse Inko source code:

```inko
def something -> ?Integer {
  Nil
}

something! # => T
```

### Defining attributes in objects

Object attributes are no longer defined in the `init` method of an object.
Instead, they must be defined in the body of an object. Before version 0.5.0 you
would write the following:

```inko
object Person {
  def init(name: String) {
    let @name = name
  }
}
```

Starting with Inko 0.5.0, you now have to write the following:

```inko
object Person {
  @name: String

  def init(name: String) {
    @name = name
  }
}
```

Using `let` with an attribute is also no longer valid. This makes it easier for
the compiler to determine what the attributes of an object are.

### Support for defining methods

Static methods can now be defined using the `static` keyword when using the
`def` keyword:

```inko
object Person {
  @name: String
  @address: String

  static def with_default_address(name: String) -> Person {
    new(name: name, address: 'Sesame Street')
  }

  def init(name: String, address: String) {
    @name = name
    @address = address
  }
}
```

The standard library has been updated to use this new syntax in a variety of
places.

### Removal of array and hash map literals

Array and hash map literals have been removed, and you now have to initialise
these types like any other object:

```inko
Array.new(10, 20, 30) # To create a new Array
Map.new               # To create a new hash map
```

Creating a map with default values requires the use of `Map.set`, which returns
the `Map` itself:

```inko
Map.new.set('name', 'Pino').set('address', 'Sesame Street')
```

### Removal of binary newline sends

Before version 0.5.0, Inko allowed you to use the following syntax:

```inko
10 < 20
  .if_true {
    something
  }
```

This would be parsed as:

```inko
(10 < 20).if_true {
  something
}
```

Starting with version 0.5.0, support for this syntax has been removed. Instead
you now need to manually wrap the binary expression in parentheses. This makes
the syntax more consistent and easier to parse.

### Simpler syntax for defining comments

Before version 0.5.0, there were three types of comments in Inko's syntax:

* Regular comments: `# foo`
* Module comments: `#! foo`
* Documentation comments (used for methods, objects, etc): `## foo`

In version 0.5. we have removed support for module and documentation comments.
Instead, you now use the regular comments for documenting your modules, types,
and methods.

## Easier writing of iterators

Writing iterators by hand can get tedious. This process is made easier by using
the newly introduced type `std::iterator::Enumerator`. Let's say we want to
provide an iterator for the `Array` type. When writing this by hand we may end
up with something as follows:

```inko
import std::iterator::Iterator

object ArrayIterator!(T) {
  @values: Array!(T)
  @index: Integer

  def init(values: Array!(T)) {
    @values = values
    @index = 0
  }
}

impl Iterator!(T) for ArrayIterator!(T) {
  def next? -> Boolean {
    @index < @values.length
  }

  def next -> ?T {
    let value = @values[@index]

    @index += 1

    value
  }
}

impl Array!(T) {
  def iter -> ArrayIterator!(T) {
    ArrayIterator.new(self)
  }
}
```

Using the `Enumerator` type we can reduce this to the following:

```inko
import std::iterator::(Enumerator, Iterator)

impl Array!(T) {
  def iter -> Iterator!(T) {
    let mut index = 0

    Enumerator.new(
      while: { index < length },
      yield: {
        let value = self[index]

        index += 1

        value
      }
    )
  }
}
```

Generators were considered as an alternative to manually written iterators.
We decided not to use generators, as adding support for this would require
extensive changes to the virtual machine. As Inko already supports lightweight
processes, generators would not be useful outside of writing iterators.

While the chosen `Enumerator` API is more verbose compared to using generators,
it offers two benefits over generators:

1. It's explicit: the code you write is what you get, instead of the compiler
   transforming it into something radically different.
1. It does not require any changes to the virtual machine.

## Random number generation

The module `std::random` has been added for generating random numbers. Using
this module we can generate arbitrary random numbers, or a random number in a
range:

```inko
import std::random

# Generate random integer that can be of any value.
random.integer

# Generate a random integer between 0 and 10.
random.integer_between(min: 0, max: 10)
```

## Lexing and parsing of Inko source code using Inko

Two types have been added for lexing and parsing Inko source code:

* `std::compiler::lexer::Lexer`
* `std::compiler::parser::Parser`

The `Lexer` type is used to tokenize an input stream of Inko source code. The
`Parser` type is used to turn this into an AST. These two types are the first
steps towards a self-hosting compiler.

Using the `Parser` type we can parse source code into an AST as follows:

```inko
import std::compiler::ast::send::Send
import std::compiler::parser::Parser

let parser = Parser.new(input: '10 + 2', file: 'example.inko')
let ast = try! parser.parse
let send = ast.children[0] as Send

send.message          # => "+"
send.arguments.length # => 1
```

The API is a bit rough around the edges here and there. We expect to make this
more useful once we start using these types to write Inko's compiler in Inko
itself.

## Bug fixes for the socket API

In 0.5.0, two use-after-free bugs in the socket API have been fixed. These bugs
could be triggered when a process was rescheduled after registering itself with
the system's socket IO poller.

## Added Range.cover?

The method `cover?` was added to `std::range::Range`. This method can be used to
check if a `Range` includes a value, without having to iterate over all values
in the range:

```inko
import std::range::Range

(1..10).cover?(5) # => True
```

## All object attributes must now be assigned in "init"

When defining an object that has one or more attributes, the compiler now
requires that the object's "init" method assigns all these attributes. This
means the following is not valid:

```inko
object Person {
  @name: String
  @address: String

  def init(name: String) {
    @name = name
  }
}
```

## Support for jemalloc

The VM can now be compiled with support for the jemalloc allocator. To do so,
compile the VM as follows:

    cargo build --release --features jemalloc

You can also use the Makefile in the `vm/` directory of the Git repository:

    make release FEATURES='jemalloc'

The official Inko builds will continue to use the system allocator.

## Reworked hashing internals

The hashing internals of the `Map` type have been reworked, inspired by how Rust
handles hashing. Two different `Map` types may now produce different hashes for
the same input value. This fixes some concurrency related bugs, and makes the
`Map` type more resilient.

## Improved support for Windows

Starting with Inko version 0.5.0 we will be providing pre-built versions of Inko
for Windows when using the GNU architecture. This means that if you are using
[ienv][ienv] inside MSYS2 (or similar), you no longer need to compile the
virtual machine from source.

While these packages can be used outside of MSYS2 (they do not depend on MSYS2),
ienv does not work without a Unix-like environment (such as MSYS2).

[changelog]: https://gitlab.com/inko-lang/inko/blob/v0.5.0/CHANGELOG.md#050-september-16-2019
[july-2019]: /news/inko-progress-report-july-2019/
[aug-2019]: /news/inko-progress-report-august-2019/
[open-collective]: https://opencollective.com/inko-lang/contribute/backer-9989/checkout
[ienv]: /manual/ienv/
