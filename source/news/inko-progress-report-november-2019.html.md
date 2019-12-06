---
title: "Inko Progress Report: November 2019"
date: 2019-12-06 15:00:00 UTC
---

The progress report for November 2019 is here! In November we released [Inko
0.6.0](/news/inko-0-6-0-has-been-released/), made improvements to the garbage
collector, and continued work on the self-hosting compiler.

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

## Inko 0.6.0

In November we released [Inko 0.6.0](/news/inko-0-6-0-has-been-released/). This
release contains additions to the standard library, improvements to the garbage
collector, and a lot more. Be sure to check out the release post for more
details!

## Garbage collector improvements

On top of the garbage collector improvements released in 0.6.0, we made several
extra improvements.

The first improvement is that we use a more efficient way of storing blocks of
memory in processes and the global allocator. This new setup allows the garbage
collector to reclaim memory blocks much faster. For processes with large heaps
this change can lead to a significant performance increase. For example, in some
of our tests this resulted on garbage collection timings being reduced from
20-30 milliseconds to less than 5 milliseconds.

The second improvement is that we have further optimised the tracing of live
objects in parallel. These improvements result in tracer threads terminating
faster than before (when needed), reducing garbage collection timings and
simplifying the code.

## Process statuses are now more compact

A process can be in different states, such as running, terminated, or waiting
for a message. We now store some of these states in a single integer by using
different bits for the different states. This allowed us to fix two bugs:

1. Processes could still receive messages after they terminated, resulting in
   those messages never being received. This could increase memory usage over
   time, until the last reference to the process is dropped.
2. When cleaning up a process after it terminated, another process can send
   messages to it, which in rare cases could lead to memory corruption.

## Array.join

The method `join` has been added to the type `std::array::Array`. This method
can be used to cast values to a `String` and join them together using a
separator:

```inko
let numbers = Array.new(10, 20, 30)

numbers.join(',') # => '10,20,30'
```

## Progress on the self-hosting compiler

Work on the self-hosting compiler continues. In the progress report for
[September 2019](/news/inko-progress-report-september-2019) we wrote about our
plans for a parallel compiler, and how processes in the compiler would
communicate and share type information. Since then we have decided to take a
different approach.

Compilers (most of the time) can be divided into the following steps:

1. Parsing
2. Type defining and checking
3. Optimisations
4. Code generation

Parsing code is easy to perform in parallel, as no shared data structures are
needed. The same goes for code generation. Performing type defining and checking
in parallel is more difficult. In a language with shared memory we could define
types sequentially, then type check the code in parallel. But Inko does not have
shared memory, which poses a problem. If the data to share is small, we could
just copy it across processes. But type information often consists of large
(recursive) data structures, and copying these between processes often is
expensive.

We spent a lot of time trying to come up with ways of dealing with this.
We realised that whatever approach we would take, it would serialise type
defining and checking, and make the compiler too complex for our liking. As such
we have decided to make the compiler a mostly parallel compiler. This means some
steps (such as parsing) are performed in parallel, while other steps (such as
type defining and checking) are performed sequentially. It's not clear yet if we
will be able to optimise code in parallel, but since most optimisations will be
simple (the most complex one being inlining of methods) it's not clear if this
matters much to begin with.

The parallel parsing stage is implemented, though we have not yet written tests
for it. We have also started work on the type defining and checking stage of the
compilation process.

## Plans for December

For December we plan to continue work on the type defining and checking stage of
the compiler. Due to the upcoming Christmas holidays it's unlikely we will
finish this, but that's OK.
