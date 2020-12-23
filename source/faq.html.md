---
title: Frequently Asked Questions
html_class: faq
keywords:
  - inko
  - faq
  - frequently asked
description: Frequently asked questions about the Inko programming language.
---

1. TOC
{:toc}

## The Inko project

### Where does the name come from?

"Inko" ("インコ") is Japanese for parakeet / parrot. Inko is an object oriented
language that uses message passing. In a way, objects talk to each other, much
like parrots can "talk" by mimicking the human voice. We also happens to like
parrots.

### Who is the author of Inko?

[Yorick Peterse](https://yorickpeterse.com/).

### What license does Inko use?

Inko is licensed under the [Mozilla Public License version
2.0](https://www.mozilla.org/en-US/MPL/2.0/).

### Why does Inko use the MPL 2.0?

The MPL 2.0 license is a permissive language that covers important topics, such
as patents, and better describes who owns the source code (compared to the MIT
license). It also comes with some requirements such as:

* Changes made to the software must be published
* A copy of the license must be included when distributing the software
* Modifications of the software must use the same (or a compatible) license

This better protects the authors and the software, and makes it more clear to
users what to expect.

For more information about the MPL 2.0 you can refer to the [MPL 2.0
FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/), or the [MPL 2.0 entry on
choosealicense.com](https://choosealicense.com/licenses/mpl-2.0/).

### Can I use Inko for a proprietary project?

Yes. The MPL 2.0 is not a viral license. This means that the MPL 2.0 license
only applies to Inko's own source code, and not any projects that link with it
(e.g. your own software).

### Why host on GitLab.com, and not GitHub?

GitLab offers more features than GitHub, and comes with built-in continuous
integration support.

### What languages were a source of inspiration for Inko?

In no particular order: Smalltalk, Self, Ruby, Erlang, and Rust.

### Inko's concurrency model looks familiar to the model used by Erlang, is this intentional?

Yes. Inko's concurrency model is heavily inspired by Erlang.

## The language

### Why use curly braces?

Curly braces are by far the most common way of starting and terminating blocks
of code, such as functions. This hopefully makes it easier to get used to Inko.

Curly braces integrate better into editors, as most have support for
automatically inserting them, or jumping to a closing curly brace.

Lastly, curly braces make the code more compact without sacrificing readability.

### Why do I have to import a module just to write to STDOUT or STDERR?

1. Not every program (or module) has to write to STDOUT or STDERR.
1. Exposing some sort of `print` method by default could lead to conflicting
   methods in a module.

### Why is the keyword for blocks called "do"

This is taken from Ruby, which uses a keyword with the same name to start a Ruby
closure.

### Why do certain methods take a "lambda", instead of a block?

Lambdas are blocks that can't capture any local variables. They are primarily
used for spawning processes, or starting other operations where the block may
outlive the scope that it's defined in.

### What was the inspiration for the error handling model of Inko?

An article titled [The Error Model](http://joeduffyblog.com/2016/02/07/the-error-model/),
by [Joe Duffy](http://joeduffyblog.com/).

### Why not use some sort of Result type for errors?

Result types and similar solutions impose a runtime cost on the happy path, even
when an error never occurs. Inko's error model doesn't suffer from the same
problem.

### What does Inko use for optional values?

We use an `Option` type, sometimes called a `Maybe` (monad). These types wrap
the data that may be optional. Before version 0.9.0 Inko used nullable types,
but these have since been removed.

### Why do I have to include error types in my method signatures, but panics don't require any extra information?

Virtually every method can panic (e.g. when running out of memory). This would
lead to overly verbose method signatures.

### Does Inko support reflection?

Yes. Inko provides support for reflection using the module `std::mirror`. This
module provides a powerful reflection system, based on the concept of
[mirrors](https://en.wikipedia.org/wiki/Mirror_(programming)).

### How can I refer to the current module?

You can use the `ThisModule` constant for this, which contains the module that
the constant is referenced from. This is used used when an object's method is
the same as a module method, and you want to call the module method from the
object's method:

```inko
def example {}

object Person {
  def example {
    ThisModule.example
  }
}
```

### How do I write a unit test?

You can use `std::test` for this:

```inko
import std::test
import std::test::assert

test.group('Integer.+') do (g) {
  g.test('Summing two Integers') {
    assert.equal(1 + 2, 3)
  }
}

test.run
```

### How does the runtime perform low level operations, such as opening a file?

The runtime uses what is known as "virtual instructions" for this. These
instructions look like regular message sends, but are compiled directly into
virtual machine instructions. Virtual instructions always use the constant
`_INKOC` as the receiver, for example:

```inko
_INKOC.integer_equals(10, 10)
```

This code would be directly compiled into the `IntegerEquals` instruction. These
virtual instructions are used in various places as the basic building blocks of
the runtime.

You should never use these instructions directly, as they are not part of the
public API and may change (or be removed) at any time.

### Does Inko support sum types and/or enums?

No.

### Does Inko support pattern matching like functional languages?

Yes, Inko offers a limited form of pattern matching. Refer to [the
manual](https://docs.inko-lang.org/manual/master/getting-started/pattern-matching/)
for more information.

### Does Inko use pass by value, or pass by reference?

Pass by value, but all values are pointers to heap allocated objects. This means
that passing an object to a method will result in that method using a copy of
_the pointer_, not the object it points to.

### Does Inko have any move semantics similar to Rust?

No.

## The compiler

### Why is the compiler written in Ruby?

Inko is not feature complete enough to write a compiler for itself.  This meant
the we had to use a different language, and Ruby happened to be a language they
were most comfortable with.

### Why not write the compiler in Rust, just like the VM?

Before writing the compiler in Ruby, the author did attempt to write it in Rust
instead. The author spent a lot of time fighting Rust's strict type system and
borrow checker. After a month or two the author decided to give up, and write
the compiler in Ruby instead.

### Will the compiler always be written in Ruby?

No. Once Inko is feature complete enough we aim to rewrite the compiler in Inko
itself.

### Does the compiler perform any work in parallel?

Not at the moment.

### Does the compiler support incremental compilation?

Not at the moment, but we hope to add support for this one day.

## The virtual machine

### Why write the VM in Rust?

While we have experience with other systems languages such as C, we do not feel
comfortable writing a virtual machine in these languages. Rust makes it much
harder to shoot yourself in the foot, comes with a nice package manager,
built-in unit testing, type inference, and other features not found in C or C++.

### Why use a garbage collector?

Manually managing memory like one does in C is prone to error. Compiler assisted
memory management, such as used by Rust, is less error prone but often more
complicated to use. Garbage collection makes memory management easy (for the
user), at the cost of (potentially) less efficient memory usage.

We feel that using a garbage collector strikes a nice balance between good
memory usage, and ease of use.

### What garbage collection algorithm is used?

The garbage collector is a generational, parallel garbage collector, based on
[Immix](http://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf).
While Immix is not commonly used, it's an excellent garbage collection
algorithm.

Inko is the only programming language out there (that we know of) that fully
implements Immix. [JikesRVM](https://www.jikesrvm.org/) also fully implements
Immix, but is targeted towards virtual machine research, and not production
software.

### How does Immix work?

The Immix paper describes this in great detail, but the brief summary is as
follows:

* Memory is divided into 32 KB aligned blocks, which in turn are divided into
  "lines". Each line is 128 aligned bytes.
* A global allocator is tasked with allocating blocks from the system, and
  handing these off to thread-local (or in case of Inko process local)
  allocators.
* Objects are allocated into free lines of blocks that still have one or more
  lines available, using bump allocation.
* The garbage collector does not operate on individual objects, instead it
  operates on lines. This means it reclaims entire lines, instead of individual
  objects.
* The garbage collector uses a set of statistics to determine which blocks can
  be reused, which are full, and which ones need to be evacuated.
* Evacuating means moving objects from one block to another. This will reuse
  existing free blocks. The decision to do so is made based on statistics from a
  previous garbage collection.
* Evacuating of objects happens while tracing through all live objects, removing
  the need for a separate pass over the entire heap.
* Free blocks are returned to the global allocator.

### Why not use OS threads, instead of green threads?

While the overhead of starting OS threads is not that big, it's still quite a
bit bigger than allocating a lightweight structure and storing this somewhere.
OS threads also typically allocate a certain stack size from the start.

Green threads give us greater control, and use fewer resources. This allows one
to spawn a large number of green threads (known as "processes" in Inko), without
using a lot of memory.

The use of green threads does require a custom scheduler, which adds extra
complexity. We feel that this trade-off was worth it, because it ultimately
makes it much easier and less scary to run lots of concurrent processes.

### Does the virtual machine support finalisation?

No.

### Does the virtual machine guarantee resources are cleaned up upon termination?

No. While the VM tries its best to release all resources, we don't guarantee
this always happens; unless you explicitly release them in your code.

### How many processes can run concurrently and in parallel?

The virtual machine has two thread pools: one for executing regular processes,
and one for processes that may perform blocking operations, such as reading from
a file.

Note that we say _concurrently_ opposed to _in parallel_. This is because it's
up to the CPU to decide how many of these threads are running in parallel.

### Can I change the number of threads used by the VM?

Yes. See [the documentation about environment
variables](https://docs.inko-lang.org/manual/master/virtual-machine/configuration/)
for more information.
