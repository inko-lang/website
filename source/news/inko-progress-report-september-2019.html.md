---
author: Yorick Peterse
title: "Inko progress report: September 2019"
date: "2019-10-05 22:15:00 UTC"
---

The progress report for September 2019 is here! In September we released version
0.5.0 of Inko, and made more progress towards a self-hosting compiler.

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang). If you would like to
donate via other means, please send an Email to
<mailto:yorick@yorickpeterse.com>.

If you would like to engage with others interested in the development of Inko,
please join the [Matrix chat
channel](https://riot.im/app/#/room/#inko-lang:matrix.org). You can also follow
the development on [Reddit](https://www.reddit.com/r/inko/), or follow the
author of Inko on [Twitter](https://archive.is/6LWOm). For more
information check out the [Community](/community) page.

## Inko 0.5.0 released

In September we released version 0.5.0 of Inko, four months after the previous
0.4.1 release. This release was packed with changes related to simplifying the
syntax, which in turn makes it easier to port the Ruby compiler to Inko.

For more information about the 0.5.0 release, take a look at [the 0.5.0 release
post](/news/inko-0-5-0-has-been-released/).

## New standard library types and methods

As part of the compiler work we added new methods and types to the standard
library, and re-organised several standard library modules so they are easier to
maintain. Such methods include `Path.join` for joining file system paths, and
`Iterator.partition` to partition iterators. For example, you can now join paths
like so:

```inko
import std::fs::path::Path

Path.new('/tmp').join('foo').to_string # => "/tmp/foo"
```

`Path.join` supports both Unix and Windows paths, including absolute Windows
paths with drive letters:

```inko
import std::fs::path::Path

Path.new('bar').join('C:\\foo').to_string # => "C:\\foo"
```

Partitioning an `Iterator` is also simple:

```inko
let pair = Array.new(10, 20, 30).iter.partition do (value) { value >= 20 }

pair.first  # => Array.new(20, 30)
pair.second # => Array.new(10)
```

We also introduced the `Pair` and `Triple` types. A `Pair` is a tuple of two
values, while a `Triple` contains three values:

```inko
import std::pair::(Pair, Triple)

Pair.new(10, 'foo').first         # => 10
Triple.new(10, 'foo', 10.5).third # => 10.5
```

We decided not to support more than three values, as custom types are better
suited for these cases. This decision is not unique to Inko, [Kotlin made the
same decision](https://blog.jetbrains.com/kotlin/migrating-tuples/).

## Progress for a self-hosting Inko compiler

In September we also started making serious progress towards a self-hosting
compiler. A [work-in-progress merge
request](https://gitlab.com/inko-lang/inko/merge_requests/81) exists, but since
it's pretty light on details we'll try to cover everything interesting here.

Let's start with what we have so far:

1. Several simple compiler passes, such as a pass used to desugar some parts of
   the AST.
1. Types for storing configuration data.
1. A basic setup for storing type information in a type database.

These are not too interesting to discuss, though I would like to highlight one
simple pass. Not because it's an exciting one, but to showcase just how simple
some of these passes can be. This pass is the pass called "HoistImports" and
hoists all `import` expressions to the top of the module. The implementation is
simple:

```inko
import std::compiler::ast::body::Body

object HoistImports {
  def run(body: Body) -> Body {
    let pair = body.children.iter.partition do (node) { node.import? }

    Body.new(children: pair.first.append(pair.second), location: body.location)
  }
}
```

This pass just grabs all `import` expressions (which can only occur at the
top-level in a module), partitions the list of nodes, then merges the two arrays
so that the imports appear first.

With the boring stuff out of the way, let's talk about the more interesting
aspect of the compiler: the design, how we plan to make it fast, and how this
compares to the Ruby compiler.

The Ruby compiler is a multi-pass compiler, and so will be the self-hosting
compiler. In case of the Ruby compiler we could probably have benefited from
using more passes, as right now there's a bit too much crammed into the passes
it has. For the Inko compiler we will be separating work across more passes,
though we won't go down the path of writing a [nano-pass
compiler](https://nanopass.org/).

The Ruby compiler we use today to compile Inko source code is a serial compiler,
and a pretty slow one at that. Compiling all the standard library tests and
modules they import takes just under 4.5 seconds. That's 4.5 seconds to compile
20 000 lines of code, excluding comments and including tests. The standard
library itself contains just under 9 000 lines of code. This puts the compiler
at a rate of about 4500 lines of code per second. This may sound impressive, but
it means large projects would take a long time to compile. GitLab's codebase
consists of over 700 000 lines of Ruby code. At 4500 lines per second it would
take 155 seconds (2.6 minutes) to compile all the source code. That's long!

With this in mind we knew a serial compiler was not going to cut it. Even a
well optimised serial compiler may need a long time to compile large projects.
Short compile times are important, so we needed a solution. Two approaches exist
for solving this problem:

1. Incremental compilation
1. Parallel compilation

Incremental compilation means that you save some sort of state that you can use
the next time, allowing you to skip files that do not need to be recompiled.
Parallel compilation means compiling multiple files in parallel (but not
necessarily compiling them incrementally).

For Inko we decided to focus on parallel compilation first, and take a look at
incremental compilation in the future. Not because we believe parallel
compilation is better, but because implementing just parallel compilation is
hard enough already.

Building a parallel compiler brings an interesting question: how are the
different threads (or lightweight processes in case of Inko) going to access
shared data, such as the modules and types that have been defined thus far? In a
language with shared memory, one might use synchronisation for this. In Inko,
processes don't share data; they communicate by passing (and copying) messages.
The data structures used for storing type information can get large, so copying
these around will be expensive and is best avoided.

A naive approach would be to spawn a single process that stores all type
information. Processes that compile source code communicate with this process to
get type information, check if one type is compatible with another, etc:

![Serial type communication](/images/september-2019-progress-report/serial.svg)

The problem with this approach is that all these processes are limited by how
fast this type database process can respond to messages. For a small program
this might not matter, but for larger programs this may result in (some) of the
work being performed in serial.

Our current idea is to instead use multiple processes called "partitions"
(inspired by the partitioning of databases). Each partition _only_ stores type
information; compilation is done by separate processes. A separate "registry"
process is used to record which partition owns a certain module. To look up a
type, a compiler process would request the partition for a given module that is
imported, then use that partition for obtaining type information. Once a module
is looked up, a compiler process may cache it so it does not need to request it
again from the registry. The registry process exists so we don't need to scan
over all partition to determine which one owns a module. This would not perform
well if the number of partition is large, or when looking up lots of unique
modules:

![Linear module lookups](/images/september-2019-progress-report/modules.svg)

Instead of partitions sending (and thus copying) entire type data structures to
compiler processes, they send type IDs. A type ID is a simple and lightweight
data structure that is cheap to copy, storing only the ID of the type and the ID
of the module that owns the type. If needed they may send more complex data
structures, but in all cases they will be optimised to make it cheap to copy
them.

Compiler processes communicate with these type partitions by sending messages
known as "queries" (taken again from databases). A query can be a message such
as "Give me the argument type IDs of method X", "Does type X respond to message
Y?", etc. The Rust compiler [uses a similar
approach](https://rust-lang.github.io/rustc-guide/query.html). Using separate
type partitions and queries results in a flow of messages that looks like this:

![Parallel type communication](/images/september-2019-progress-report/parallel.svg)

Registry operations are performed in serial, as there is only one registry
process. Since these operations are simple (they are just hash lookups), they
won't create a bottleneck. Compiler processes will cache these lookups locally,
so frequently imported modules only need a single lookup per compiler process.
The use of type IDs is similar to entities in an [Entity Component
System](https://en.wikipedia.org/wiki/Entity_component_system). Compiler
processes will use these type IDs and other data obtained from a type partition
to perform type checking and inference.

Type checking and inference is done by walking a desugared AST and annotating
nodes with their type IDs. We also need to store data such as local variable
scoping for closures, but we haven't decided yet on how we will do this. Other
passes such as optimisations and code generation will be easier to perform in
parallel, as these passes do not mutate any shared data structures.

Our goal is to get the compiler to compile the standard library and all its
tests in two seconds. For this to happen, we need to compile the code at 10 000
lines per second. Achieving this goal may prove difficult, so we may have to
settle for longer compile times for the first version of the self-hosting
compiler. Adding support for incremental compilation in the future will
also help cut down compilation times, but we will postpone adding support for
incremental compilation until deemed necessary.

## Plans for October

In October we will continue working on the compiler, and hope to make serious
progress on the type checking and inference passes. Other passes such as code
generation will probably have to wait until November, depending on how much
progress we make.
