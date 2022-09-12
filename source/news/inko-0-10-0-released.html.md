---
author: Yorick Peterse
title: "Inko 0.10.0 released"
date: 2022-09-12 14:00:00 UTC
---

It's been almost two years since the last Inko release, and 1.5 years since we
started work on drastically changing Inko to make it a more compelling language.
Today we're pleased to announce the release of version 0.10.0. As this release
contains so many changes we'll start by (re)introducing Inko, discuss why it
took so long to release a new version, and of course discuss the changes
themselves.

## Table of contents
{:.no_toc}

* TOC
{:toc}

## What is Inko?

Inko is a statically typed language for building concurrent software with
confidence. Inko offers various features such as deterministic automatic memory
management, move semantics, efficient and elegant error handling, type-safe
concurrency support, static typing, and more.

Inko is an interpreted language with a custom bytecode virtual machine and
compiler, both written in Rust. Inko is easy and fast to install, and supports
Linux, macOS and Windows.

Inko is useful for writing all sorts of applications, from HTTP servers and
databases to simple command-line programs. As such it competes with languages
such as Ruby, Python, Erlang, and Go.

## What happened since the last release?

Inko used to use a garbage collector for memory management, and a concurrency
API similar to Erlang. Both of these have their issues: garbage collectors are
notoriously unpredictable, and may require a lot of tuning. Erlang's concurrency
API in turn is difficult to make type-safe. We first started looking into
solving these issues [over two years
ago](https://gitlab.com/inko-lang/inko/-/issues/207), but at the time we
couldn't come up with a viable solution.

Along the way we came across the paper ["Ownership You Can Count On: A Hybrid
Approach to Safe Explicit Memory
Management"](https://www.semanticscholar.org/paper/Ownership-You-Can-Count-On/d0f2d28962d2a50d1914f0af8243d3f382fe077c)
([mirrored here](/papers/ownership.pdf)). The paper discusses a form of object
ownership that's easy to adopt, without needing an overly complicated type
system or borrow checker. While we're not the first to come across this paper
(e.g. [Nim considered it back in
2019](https://github.com/nim-lang/RFCs/issues/144)), it does seem we're the
first to implement it fully. Reading the paper lead to the creation of [this
merge request](https://gitlab.com/inko-lang/inko/-/merge_requests/120), in which
we started work on moving away from using a garbage collector and towards using
single ownership and move semantics for memory management.

Along the way we came across the paper ["Uniqueness and Reference Immutability
for Safe Parallelism"](https://www.microsoft.com/en-us/research/publication/uniqueness-and-reference-immutability-for-safe-parallelism/).
Reading the paper we realised the setup discussed in the paper could prove
compelling when combined with single ownership and move semantics. Most notably
it would allow moving of data between processes without the need for deep
copying or synchronisation. If you've ever used
[Pony](https://www.ponylang.io/), the setup discussed in the paper may sound
familiar and that's no coincidence: Pony's approach to concurrency appears to be
based on this paper, or at least draws inspiration from it. Unlike Pony, our
approach involves fewer reference capabilities, which should make it easier to
work with.

Of course reading papers is one thing, but changing an entire language is a
different beast entirely, and what's what we've been up to for the last 1.5
years or so. Inko 0.10.0 is the result of this work, and we believe it will make
Inko a compelling language to use in the coming years.

## Installing Inko

The easier way to install Inko is using [Inko's version
manager](https://docs.inko-lang.org/manual/latest/getting-started/ivm/):

```bash
ivm install 0.10.0
```

You can then set it as your default version as follows:

```bash
ivm default 0.10.0
```

After this you can use the `inko` executable like any other.

### Arch Linux

If you're using Arch Linux you can also install Inko using the AUR and your
favourite AUR wrapper:

```bash
yay -S inko
```

Or if you want to build it manually, use these steps:

```bash
git clone https://aur.archlinux.org/inko.git
cd inko
makepkg -si
```

### macOS

Users of macOS can also use Homebrew:

```bash
brew install inko
```

Note that we don't maintain the Homebrew formula ourselves and as such it may
take a while to be updated to version 0.10.0.

### From source

You can also build from source:

```bash
git clone https://gitlab.com/inko-lang/inko.git --branch=v0.10.0
cd inko

# This installs Inko into /usr
make build PREFIX=/usr
make install PREFIX=/usr
```

If you want to contribute to Inko you'll need to build the `master` branch like
so:

```bash
git clone https://gitlab.com/inko-lang/inko.git
cd inko
cargo build --release
```

In this case the executable is located at `./target/release/inko`.

## Changes included in 0.10.0

Before take a look at what's included in this release it's important to set the
right expectations. Inko is only at version 0.10, and we still have a long road
ahead of us before reaching version 1.0. This means you may encounter bugs,
compiler crashes, performance issues, or missing/lacking documentation. If you
encounter any problems, please [report them
on our issue tracker](https://gitlab.com/inko-lang/inko/-/issues/new).

With that said, let's dive into the changes included in this release.

### Single ownership of values

Single ownership is a way of managing memory by assigning owners to values, and
discarding (known as "dropping") of these values when the owner is done with
them. Typically values start of as being owned by the surrounding scope, but
ownership can be transferred by "moving" the values. A move can be an assignment
to a variable or field, or passing the value as an argument.

Using single ownership means automatic memory management is deterministic and
predictable, and doesn't require a garbage collector or (atomic) reference
counting. Not using a garbage collector means not having to spend countless
hours tweaking its various settings or worse: having to resort to hacks such as
[allocating a 10 GiB byte
array](https://blog.twitch.tv/nl-nl/2019/04/10/go-memory-ballast-how-i-learnt-to-stop-worrying-and-love-the-heap/),
because the garbage collector doesn't let you tweak it in the first place.

To illustrate what single ownership looks like in Inko, consider this simple
example:

```inko
let a = [10, 20, 30]
let b = a
```

When the array literal (`[10, 20, 30]`) is first created, its owner is the
surrounding scope. Assigning the value to `a` transfers ownership to `a`.
Assigning `a` to `b` then transfers ownership to `b`, disallowing the use of `a`
from this point on. If `b` goes out of scope and its value isn't moved, it drops
its value.

In Inko there are four kinds of values: owned values, immutable references,
mutable references, and unique values (which we'll cover in the next section);
each with its own set of rules. Values start out as owned, and when these are no
longer needed they are dropped. References are created when you need to
temporarily borrow a value but don't want to drop it when you're done with it.
For example:

```inko
let a = [10, 20, 30] # => Array[Int]
let b = ref a        # => ref Array[Int]
```

When `b` is no longer in use, only the reference is discarded; not the value it
points to (`a` in this case). Mutation is restricted to owned values and mutable
references (created using the `mut` keyword), giving you greater control over
who gets to mutate what.

Unlike Rust, Inko allows you to have both mutable and immutable references to
the same value at the same time. You're also allowed to move the value pointed
to while references exist. This makes writing software with Inko easier, and
certain patterns that are difficult in Rust (e.g. self-referential data
structures) are trivial to implement in Inko. For example, here's how you'd
define a doubly-linked list:

```inko
class Node[T] {
  # These are the class' fields and their types.
  let @next: Option[Node[T]]
  let @previous: Option[mut Node[T]]
  let @value: T
}

class List[T] {
  let @head: Option[Node[T]]
  let @tail: Option[mut Node[T]]
}
```

In Rust this would require the use of (unsafe) raw pointers, indexes
(introducing extra indirection), or more complicated alternatives.

Inko makes this possible by _not_ performing all safety checks at compile-time,
instead performing some of them at runtime. In particular, each owned value
tracks its number of (im)mutable references. If an owned value is dropped while
references to it still exist, the program aborts with an error. Creating and
discarding references in turn mutates this counter accordingly. Many of these
reference count changes can be optimised away, and indeed Inko's compiler does
just that; though there's a lot of room for improvement. Integers, floats and
strings are value types, meaning they are copied when moved. For strings we use
atomic reference counting, meaning that 10 copies of a 1 GiB string only need 1
GiB of memory.

For a systems language such as Rust, managing reference counts at runtime may
not be desirable, though it's not unheard of in Rust: types such as `Arc` and
`RefCell` do just that in Rust. For a more high-level language such as Inko we
believe it's a compelling trade-off, as it provides you the benefits of single
ownership but at a smaller cost.

### Type-safe concurrency

Inspired by Erlang, Inko uses lightweight isolated threads known as "lightweight
processes". These processes don't share memory and communicate by sending
messages. This is built on top of Inko's ownership model: when you send values
to a process, the values are moved into the receiving process and are no longer
available to the sender.

Value types are copied when sent, but for other types we have to guarantee the
sender retains no references to the values, and that the values don't contain
references to values still in use by the sender. In other words, we have to
guarantee the value is unique (in that the value itself is the only reference
to/from it). For this Inko uses an approach similar to Pony: recovery and unique
values. Unlike Pony our implementation is simpler to use, due to the combination
of single ownership and having fewer reference capabilities.

A unique value is essentially a box of which the compiler knows nothing outside
the box points into it, and nothing inside the box points to the outside; though
values in the box can point to each other just fine.

Recovery is the process of taking an owned value and turning it into a unique
value, or turning a unique value back into an owned value. Recovery is simple
yet effective: Inko has a `recover` keyword, which takes either a single
expression or a block:

```inko
recover [10, 20]     # => uni Array[Int]
recover { [10, 20] } # => uni Array[Int]
```

Inside a recover block variables defined outside it are only available if they
are value types or unique, everything else can't be used:

```inko
let a = [10, 20]
let b = recover a # => invalid, because `a` is defined outside the `recover`
```

This leads to the following observation: if outside owned values and references
aren't available, then any such value created inside the recover expression can
only point to or contain other values created in the recover expression. This
means that if the recover expression returns an owned value, it's safe to
convert it into a unique value, because no outside references to it will exist
any more at that point.

The same is true the other way around: unique values _are_ available to recover
expressions. The value returned by a recover expression in turn is moved into
its new value/type. This means that if the recover expression returns a unique
value, it's safe to turn it into an owned value.

Using unique values comes with restrictions, such as not being able to call
methods on them if they take arguments that aren't "sendable". A value is
"sendable" if it's a value type or a unique type. Under certain conditions we
can relax these restrictions, making it easier to call methods on unique values.
For example, if a method is immutable and doesn't take arguments, any owned
value it returns or throws must have been created as part of the method call.
This means it's safe to treat the value as sendable, because no outside
references to it can exist when its produced.

Creating processes is done by defining classes marked as `async`:

```inko
class async Counter {
  let @value: Int
}
```

When creating instances of such classes, Inko spawns a new process. Processes
are a bit like generators in that they don't do anything by default, instead
they act upon messages sent to them. Messages are defined as methods marked as
`async`, and are processed in FIFO order:

```inko
class async Counter {
  let @value: Int

  fn async mut increment(value: Int) {
    @value += value
  }

  fn async value -> Int {
    @value.clone
  }
}
```

Sending messages is done using Inko's regular method call syntax:

```inko
let counter = Counter { @value = 0 }

counter.increment(1)
counter.increment(1)
counter.value # => 2
```

When sending messages Inko defaults to awaiting the result right away. This
makes it easier to transition from regular types to processes, while also making
async calls more explicit. How do we _not_ wait right away? Simple: just stick
`async` in front of the expression:

```inko
let counter = Counter { @value = 0 }

async counter.increment(1)
async counter.increment(1)
```

In this case you get a `Future` back instead of the message result, and you can
resolve it using the method `Future.await`:

```inko
let counter = Counter { @value = 0 }

async counter.increment(1)
async counter.increment(1)

let future = async counter.value

future.await # => 2
```

In all cases Inko's scheduler takes care of suspending and rescheduling the
process, ensuring the underlying OS thread is available to perform other work.

Inko's approach to concurrency makes it easy to write efficient concurrent
software, without having to worry about race conditions and without the need for
deep copying values when sending them between processes.

### A new compiler

Inko's compiler is now written in Rust instead of Ruby. While originally the
idea was to work towards a self-hosting compiler we realised this isn't worth
the time and effort. A self-hosting compiler complicates the development process
as you have to maintain two compilers, while also complicating the installation
process. Perhaps in the future we'll revise this, but at least not in the coming
years.

Inko's compiler is a typical batch compiler consisting of many phases, somewhat
inspired by the [Nanopass framework](https://nanopass.org/). First we parse the
source code into an AST, which is then lowered into Inko's high-level
intermediate representation (creatively called "HIR"). HIR is basically just the
AST with some small changes, and is used for type checking. Type checking is
performed on HIR and annotates HIR with their types. Once done, we lower HIR
into Inko's mid-level representation called "MIR". MIR is where we enforce
single ownership, perform optimisations, compile pattern matching, and more.

The final step is to generate bytecode from MIR, which is then written to an
Inko bytecode image. An image is just a file containing all the bytecode for an
Inko program, somewhat similar to a Java JAR.

The new compiler is quite fast, even though we have spent little time optimising
it: compiling Inko's test suite, which includes the entire standard library,
only takes about 75 milliseconds. The exact time needed will probably change as
we add more optimisations and improve the compiler, but it's a good start.

For more details on the compiler, take a look at [this
section](https://docs.inko-lang.org/manual/latest/internals/compiler/) of the
manual.

### Better type inference

As part of the compiler rewrite, type inference improved dramatically. Inko is
also able to infer types based on how they're used later:

```inko
let a = [] # `a` is inferred as `Array[Int]` based on the `push()` below

a.push(10)
```

This works for all generic types, not just arrays:

```inko
let mut a = Option.None # `a` inferred as `Option[Int]`

a = Option.Some(42)
```

Note that Inko doesn't have global type inference, meaning type signatures for
methods are necessary. This is by design, as we feel this makes it easier to
understand method definitions.

### Symbol visibility

Symbols (classes, constants, etc) now default to being private to the modules
they're defined in, instead of always being public. You can make symbols public
using the `pub` keyword:

```inko
class PrivateClass {}
class pub PublicClass {}

let A = 10
let pub A = 10
```

### Accessing fields directly

Inko now supports direct access of fields (depending on their visibility). The
syntax is the same as getter/setter methods:

```inko
class Person {
  let @name: String
}

let alice = Person { @name = 'Alice' }

alice.name # => 'Alice'
alice.name = 'Bob'
alice.name # => 'Bob'
```

Using the same syntax makes it easier to turn a field into a getter/setter
method, without having to change all uses of the field. Note that while the
syntax is the same, Inko's compiler doesn't generate getter/setter methods for
you; instead accessing a field is just that: accessing a field.

### Algebraic data types

Inko now supports algebraic data types, sometimes also known as sum types. These
are defined using `class enum` like so:

```inko
class enum Result[T, E] {
  case Ok(T)
  case Error(E)
}
```

Creating instances of such types is done using regular method calls:

```inko
# Result.Ok() and Result.Error() are just methods generated by the compiler.
Result.Ok(42)
Result.Error('Oh no!')
```

When used for pattern matching, the compiler ensures the match is exhaustive,
and will suggest any missing cases when the match isn't exhaustive.

### Tuples

Inko now supports tuples with up to eight values, instead of only supporting up
to three values. Tuples are also available in type signatures:

```inko
let a: (Int, String) = (10, 'test')
```

Tuples are accessed as follows:

```inko
a.0 # => 10
a.1 # => 'test'
```

Tuples are just regular classes, such as `Tuple2`, `Tuple3` and `Tuple4`. The
compiler knows what class to use for a tuple based on the number of values it
stores. This means the above is essentially syntax sugar for the following:

```inko
let a: Tuple2[Int, String] = Tuple2 { @0 = 10, @1 = 'test' }
```

### Pattern matching

Inko now supports full pattern matching, instead of the limited form of pattern
matching is used to support. Patterns such as enum variants, class literals,
tuples, and integer literals are all supported. Guards are also supported

Here's what pattern matching looks like:

```inko
match Option.Some(42) {
  case Some(num) if num >= 40 and num <= 50 -> 'yay'
  case _ -> 'nay'
}

match (10, 'testing') {
  case (num, 'testing') if num < 20 -> 'yay'
  case _ -> 'nay'
}

class Person {
  let @name: String
}

let alice = Person { @name = 'Alice' }

match alice {
  case { @name = 'Alice' } -> "It's Alice!"
  case { @name = 'Bob' } -> "It's Bob!"
  case _ -> "It's somebody else!"
}
```

Match expressions are compiled into decision trees which are then lowered into
MIR. When matching against an enum, the match is compiled into a jump table.

For more information about pattern matching, refer to [the
manual](https://docs.inko-lang.org/manual/latest/getting-started/pattern-matching/).

### Installing Inko is easier

Now that the compiler is written in Rust and various other dependencies have
been removed, installing Inko couldn't be easier: a simple `cargo build
--release` is all it takes. The time it takes to compile Inko has also been
reduced, with release builds taking just under 10 seconds on modern hardware.

### Inko now uses the system allocator

Inko used an allocator based on
[Immix](https://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf).
While this allocator is excellent when paired with a garbage collector, it's
less useful without. Most notably, handling fragmentation proved difficult.
Along the way we realised our allocator was unlikely to ever outperform well
established allocators such as [jemalloc](https://jemalloc.net/), and that our
time was better spent elsewhere. Because of this, Inko now uses the system
allocator for managing memory, and has built-in (optional) support for using
jemalloc.

For now all Inko objects are allocated onto the heap, but stack allocating
objects is something we'll look into in the future.

### Improved standard library

The standard library received various additions, such as extra methods and
improvements.

`Range` is no longer generic and only supports `Int` values, as this is what
ranges are mostly used for. The `..` and `...` range syntax is removed, in
favour of using regular methods (e.g. `Int.until` and `Int.to`).

`Map` now preserves the insertion order of key-value pairs, making it easier to
test, serialise and display `Map` values. The load factor is increased to 90%,
reducing the amount of rehashing necessary.

`DateTime` uses a different algorithm for breaking timestamps, based on [this
article](http://howardhinnant.github.io/date_algorithms.html) by Howard Hinnant.

`String.length` is removed in favour of using `String.chars`, which returns an
iterator over the grapheme clusters of the string. This makes it more explicit
that counting extended grapheme clusters is potentially expensive. We also added
more methods to `String`, such as `String.contains?`, `String.pad_start` and
`String.pad_end`, and improved the implementation of existing methods such as
`String.split`.

Formatting and parsing integers is improved by using dedicated methods for the
different integer bases, instead of using a single method that supports many
bases (and panics when the base is invalid). For example, instead of this:

```inko
Int.parse('fff', radix: 16)
```

You now write the following:

```inko
Int.from_base16('fff')
```

The first approach isn't ideal as `Int.parse` would panic if `radix` was e.g.
100, as returning a `None` would hide the error of the base being invalid. The
new approach doesn't suffer from this, and has the added benefit of using a more
descriptive method name.

The module `std::env` no longer support setting environment variables, as
changing these can lead to issues when interacting with C code through Inko's
FFI, and it just isn't useful. The VM now caches environment variables at
startup, making methods such as `std::env.get` more efficient.

## What's next

For the next release of Inko we'll focus on building upon the changes included
in 0.10.0, such as by improving the standard library and the compiler's test
suite.

To make sharing Inko code easier we'll start looking into building a [package
manager for Inko](https://gitlab.com/inko-lang/inko/-/issues/225), though this
is unlikely to make it into the next release due to the scope of the work.

We'll also continue looking into [compiling Inko to machine
code](https://gitlab.com/inko-lang/inko/-/issues/248). This isn't something
planned for the next release specifically, but rather something we're looking
into on the side.

## Following and supporting Inko

If Inko sounds like an interesting project, consider joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). You
can also follow along on the [/r/inko
subreddit](https://www.reddit.com/r/inko/).

We are working on Inko full-time and using our savings to cover the costs. If
you'd like to support the continued development of Inko, please consider
donating using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse).
Every donation, no matter how small, is greatly appreciated.
