---
title: "Inko 0.6.0 has been released"
date: 2019-11-17 14:15:44 UTC
---

Inko 0.6.0 has been released, featuring improvements to the garbage collector,
additions to the standard library, more efficient sending of messages between
processes, and various other changes.

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/). If you would like to
donate via other means, please send an Email to
<mailto:yorick@yorickpeterse.com>.

If you would like to engage with others interested in the development of Inko,
please join the [Matrix chat
channel](https://riot.im/app/#/room/#inko-lang:matrix.org). You can also follow
the development on [Reddit](https://www.reddit.com/r/inko/), or follow the
author of Inko on [Twitter](https://twitter.com/yorickpeterse). For more
information check out the [Community](/community) page.

## New standard library additions

Inko 0.6.0 adds various new methods and types to the standard library.

### Object.not_nil?

The method `not_nil?` is available to all objects defined, and allows you to
check if a value is `Nil` or not. This method is useful when you have an
optional type (e.g. `?String`) and you want to explicitly check if the value is
`Nil` or not:

```inko
Nil.not_nil?    # => False
String.not_nil? # => True

let number: ?Integer = 10

number.not_nil? # => True
```

Using this method you no longer have to write `thing.nil?.not`, instead you can
just use `thing.not_nil?`.

### Iterator.any?

The method `any?` has been added to `std::iterator::Iterator`. This method takes
a closure and will return `True` if the closure returns `True` for a value in
the `Iterator`, stopping iteration when it finds such a value:

```inko
let numbers = Array.new(10, 20, 30)

numbers.any? do (number) { number > 10 } # => True
numbers.any? do (number) { number > 30 } # => False
```

### Iterator.select?

The method `any?` has been added to `std::iterator::Iterator`. This method takes
a closure and will produce a new `Iterator` that includes every value for which
the closure returned `True`:

```inko
let numbers = Array.new(10, 20, 30)

numbers.iter.select do (number) { number > 10 }.to_array # => Array.new(20, 30)
```

### Integer.times

The method `times` has been added to `std::integer::Integer`. This method
returns an `Iterator` that produces values ranging from zero to (but not
including) the integer value:

```inko
4.times.to_array # => Array.new(0, 1, 2, 3)
```

This method is useful when you want to call the same closure several times:

```inko
4.times.each do (number) {
  # ...
}
```

If you just want to call the closure and don't care about the integer argument
passed to it, you can define the argument name as `_`:

```inko
4.times.each do (_) {
  # ...
}
```

For now this won't do anything special, but in the future this will ensure the
compiler adds no warning if the argument is not used anywhere.

### Pair and Triple types

The module `std::pair` has been added, defining the types `Pair` and `Triple`. A
`Pair` is a tuple of two values, and a `Triple` is a tuple of three values. Inko
does not support N-ary tuples (or tuples with more than three values), as custom
types created using the `object` keyword are a better fit for such cases.

### Iterator.partition

The method `partition` has been added to `std::iterator::Iterator`. This method
is used to partition an `Iterator` into a `Pair` of two arrays: an array
containing values for which a provided closure returned `True`, and an array
containing values for which the closure returned `False`:

```inko
let numbers = Array.new(10, 20, 30, 40)
let partition = numbers.iter.partition do (value) { value < 30 }

partition.first  # => Array.new(10, 20)
partition.second # => Array.new(30, 40)
```

### String.byte

The method `byte` has been added to `std::string::String`. This method can be
used to get a single byte given a byte index. This is useful when you want to
extract bytes from a `String`, but don't want to allocate a `ByteArray`:

```inko
'inko'.byte(0) # => 105
```

### Path.join

The method `join` has been added to `std::fs::path::Path`. This method can be
used to join a `Path` with a type that implements `std::fs::path::ToPath`, such
as another `Path` or a `String`:

```inko
import std::fs::path::Path

Path.new('foo').join('bar') # => Path.new('foo/bar')
```

This method supports both Unix and Windows file path separators.

### Path.absolute?

The method `absolute?` has been added to `std::fs::path::Path`. This method
returns `True` for an absolute path, `False` otherwise:

```inko
import std::fs::path::Path

Path.new('foo').absolute?  # => False
Path.new('/foo').absolute? # => True
```

### Path.relative?

The method `relative?` has been added to `std::fs::path::Path`. This method
returns `True` for a relative path, `False` otherwise:

```inko
import std::fs::path::Path

Path.new('foo').relative?  # => True
Path.new('/foo').relative? # => False
```

## Renaming of the AST Expressions type

The type `std::ast::expressions::Expressions` has been renamed to `Body`, and
the module has been renamed to `std::ast::body`.

## Removal of asynchronous finalisation

Various Inko object use data structures that need to be finalised/deallocated
when the Inko object is garbage collected. Before Inko 0.6.0, a separate pool of
threads was used to finalise these objects some time after they became garbage.

Starting with Inko 0.6.0, this mechanism has been removed. Instead, objects are
now finalised when their memory is reused after they have been garbage
collected. This simplifies the virtual machine, and for most programs should not
impact memory usage.

When a process terminates we still finalise its objects right away, but this may
change in the future.

## Garbage collector bug fixes and performance improvements

For Inko 0.6.0 we rewrote various parts of the garbage collector. In the
[progress report for October 2019](/news/inko-progress-report-october-2019/) we
discussed how we ran into some garbage collector bugs in October, and how they
were severe enough that we could not ignore them. We are pleased to announce
that all bugs we have found have been fixed, and that we have also improved the
performance of our parallel generational garbage collector.

The garbage collector improvements are attributed to two big changes:

1. We use a new strategy for remembering cross generational pointers.
1. We now trace objects in parallel, instead of only tracing stack frames in
   parallel.

The new strategy for cross generational pointers is discussed in detail in the
October progress report. In short, we use a chunked list for remembering mature
pointers, and a per-object bit to prevent duplicates. When promoting objects we
use a specialised tracing procedure. When this procedure encounters a young
pointer, we remembered the promoted (and now mature) object in the remembered
set; instead of remembering all promoted objects.

The parallel tracing changes can greatly improve performance for large heaps,
though even small heaps will benefit. Before Inko 0.6.0 we only processed stack
frames in parallel, tracing all objects in those frames sequentially. While this
was easy to implement, it only provided limited performance improvements over
performing all work sequentially. In our new setup we trace objects in parallel,
using a pool of tracer threads that use [work
stealing](https://en.wikipedia.org/wiki/Work_stealing). Instead of using a
fixed-size thread pool, we spawn these threads on the fly. In the future we may
decide to also reuse OS threads in some way, removing the overhead that comes
with spawning OS threads.

For small heaps we expect garbage collection timings between 500 microseconds
and 2 milliseconds. For larger heaps we expect that garbage collection will take
between 1 and 10 milliseconds. These timings will vary based on the number of
objects that need to be promoted and/or evacuated (to combat fragmentation), as
doing so is expensive and involves some synchronisation.

As an example: using the default garbage collection settings, Inko's own test
suite never triggers garbage collection, as tests don't allocate enough memory
before they finish. If we reduce the garbage collection threshold from the
default 1024 memory blocks to 32 blocks, most collections take less than one
millisecond.

In the future we can implement other performance improvements, such as
dynamically adjusting the number of garbage collection threads. For now we will
postpone such improvements so we can instead focus on working towards a
self-hosting Inko compiler.

For more information about all the garbage collector changes, consider taking a
look at commit [347ade](https://gitlab.com/inko-lang/inko/commit/347ade205d68084d1ab742cdfbe6e67c3a1a9de3).

## Reworked sending of process messages

Before Inko 0.6.0, sending a message to a process involved two steps:

1. The message was copied into a separate mailbox heap owned by the receiving
   process.
2. The receiving process would copy the message from the mailbox heap into its
   local heap.

These steps ensured a process could never directly refer to memory in the
mailbox, which simplified the garbage collector implementation.

Starting with Inko 0.6.0 processes that send messages allocate directly into the
local heap of a process, using a lock to ensure this does not happen when the
receiving process is garbage collected. The receiving process never uses a lock
at run time. Using this approach we reduce the amount of memory every process
needs when receiving messages, and we can remove a lot of code related to
garbage collecting process mailboxes.

In the current implementation, a process that is garbage collected will block
other processes from sending messages to it, until garbage collection finishes.
In the future we aim to improve this by rescheduling the sending processes if
they can not acquire the lock.

## New environment variables for tuning performance

As part of the garbage collection changes we have changed several of the
environment variables used to tweak various virtual machine settings. The
`INKO_CONCURRENCY` variable has been replaced with the following variables:

* `INKO_PRIMARY_THREADS`: controls the number of threads used for running
  regular processes.
* `INKO_BLOCKING_THREADS`: controls the number of threads used for running
  processes that perform blocking operations.
* `INKO_GC_THREADS`: controls the number of threads used in the fixed-size
  garbage collection coordination thread pool.
* `INKO_TRACER_THREADS`: controls the number of threads spawned for tracing
  objects. Each process collected will have its own pool of tracers, spawned
  when needed and terminated when all work is done.

Both `INKO_GC_THREADS` and `INKO_TRACER_THREADS` default to _half_ the number of
CPU cores, to reduce the amount of threads fighting over CPU time.

## Inko now requires 64-bits

The instruction of the new remembered set requires us to tag a third bit in a
particular pointer. On 32-bits platforms only the lower two bits are unused,
while on 64-bits platforms the lower three bits are unused. Since we need to
make use of a third bit, Inko now requires 64-bits platforms.
