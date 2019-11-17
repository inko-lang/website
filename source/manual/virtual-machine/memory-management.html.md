---
title: Memory management
---
<!-- vale off -->

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

IVM uses garbage collection for reclaiming memory. Both the garbage collector
and allocator are based on [Immix][immix]. For more information on Immix, see
the provided paper. Some more information on this can also be found in the FAQ
entry ["How does Immix work?"](/faq#header-how-does-immix-work).

## Allocator

The allocator allocates memory in 8 KB blocks of aligned memory. This means that
allocating an object for the first time will result in a 8 KB block being
assigned to the process performing the allocation. Objects are allocated into
these blocks using bump allocation.

## Garbage collector

The garbage collector is a parallel, generational garbage collector. Multiple
processes can be collected in parallel, and objects are traced in parallel using
a pool of OS threads.

A process can not run while it is being garbage collected, but _only_ the
process to garbage collect will be suspended, while all others can continue to
run as normal.

The source code for the Immix implementation and allocator can be found in
[vm/src/immix][src-immix]. The various garbage collectors are located in
[vm/src/gc][src-gc].

### Object aging

Each generation is divided into one or more "buckets". A bucket is a data
structure that contains information such as the blocks of memory that belong to
it, various histograms used by the garbage collector, and meta data such as the
age of the objects in the bucket.

Each generation has one or more buckets, acting as survivor spaces. The young
generation currently has four buckets, of which one is the "eden space". The
eden space is the bucket where new objects are allocated into. The bucket with
age `0` is the eden space.

The age of the objects in a bucket is tracked as a signed integer stored in the
bucket. For the young generation, the starting ages are as follows:

| Bucket | Age
|:-------|:-----
| 0      | 0
| 1      | -1
| 2      | -2
| 3      | -3

Bucket 0 has age 0, making it the current eden space.  Every garbage collection
cycle the ages of these buckets are incremented. This means that after a garbage
collection cycle the ages will be as follows:

| Bucket | Age
|:-------|:-----
| 0      | 1
| 1      | 0
| 2      | -1
| 3      | -2

Now bucket 1 is the eden space, because its age is `0`. This process will
continue indefinitely. When a bucket reaches age `3`, its _live_ objects are
copied into the next generation, and its age is reset to `0`.

This setup is somewhat similar to a circular buffer, and is based on the
fact that all objects either age or become garbage, instead of staying the same
age. Using this system removes the need for copying objects every time they age,
reducing the time spent garbage collecting. This is quite important because
while the garbage collector is parallel, it requires a certain amount of
synchronisation when copying objects, and this can be quite expensive depending
on the number of objects to copy.

### Reclaiming objects

Immix doesn't reclaim individual objects, instead it reclaims entire blocks of
memory. This greatly speeds up garbage collection performance, but also poses a
bit of a problem: if an object wraps a certain structure (e.g. a socket), we
would leak that structure.

IVM solves this by finalising such structures when reusing their memory. When we
are about to allocate a new object, we first check if the memory contains an
object that has yet to be finalised. If so, we finalise it before overwriting
the memory.

Finalisation is not exposed to the language, instead it's a system used to
reclaim memory of certain data structures (sockets, file handles, and so on),
without having to do this during a garbage collection cycle.

The VM guarantees that any object that needs to be finalised will eventually be
finalised. However, the VM does not guarantee _when_ this will happen. This
means you don't _have to_ (for example) close a file handle, though it is
strongly recommended you do so as soon as you no longer need the object. These
guarantees may be broken due to a bug, so it's best to not rely on them too
much.

## Process heaps

Each process has its own heap, which allows the garbage collector to collect
processes independently; without having to pause _all_ processes. When sending a
message, the message is (deep) copied into the receiving process' heap.

## Permanent heap

The permanent heap is a global heap that is not garbage collected. This heap is
primarily used for storing permanent objects, such as modules. Objects in this
heap can never refer to non permanent objects, so writing any non permanent
object to a permanent object will result in a copy being written instead. This
removes the need for the GC having to check the permanent heap to determine if a
process-local object can be garbage collected, at the cost of requiring a bit
more memory.

## Object layout

Each object is exactly 32 bytes in size, and contains 3 fields:

1. A pointer to the prototype of the object, if any.
1. A pointer to the attributes map of the object, if any.
1. A pointer to the value wrapped by the object, if any.

The value pointer may point to a file, a socket, an array of other objects, and
so on. This produces the following layout:

```
        Object
+----------------------+
| prototype (8 bytes)  |
+----------------------+
| attributes (8 bytes) |
+----------------------+
| value (16 bytes)     |
+----------------------+
```

The attributes field is a tagged pointer, which can have the lower three bits set
as follows:

| Lower two bits  | Meaning
|:----------------|:-------------------------------------------------------------
| `000`           | The field contains a regular pointer to the attributes.
| `001`           | The current object is in the process of being forwarded.
| `010`           | The field is a forwarding pointer that should be resolved.
| `100`           | This object has been remembered in the remembered set.

Encoding this data directly into the attributes saves us an extra 8 bytes of
memory per object. Some of these bits can be combined. For example, if the lower
three bits are `011` then it means the object is both remembered and being
forwarded.

The attributes field is a pointer to a HashMap, allocated when necessary.

The value is 16 bytes because it is a Rust enum, which contains both a pointer
to the value and an 8 byte "tag" that specifies what kind of value is wrapped.

While this particular setup requires some extra indirection (instead of
embedding certain values directly), it drastically simplifies the allocator and
garbage collector, as all objects are of an identical size.

## Allocation optimisations

Integers that fit in a 62 bits signed integer are not heap allocated, instead
IVM uses [tagged pointers][tagged-pointers]. 64 bits integers are heap
allocated, while integers larger than 64 bits are allocated as arbitrary
precision integers. When an integer is tagged, the first lower bit of the
pointer is set to `1`.

Tagging an integer is done as follows:

```rust
let integer: i64 = 1024
let tagged = (integer << 1) | 1;

println!("{:b}", tagged); // => 100000000001
```

Strings use atomic reference counting, without support for weak references. This
allows strings to be sent to many processes, without having to duplicate the
memory.

All integer, float, and string literals (`10`, `'hello'`, `10.5`, etc.) are
allocated on the permanent heap when the VM parses a bytecode file.

[immix]: http://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf
[tagged-pointers]: https://en.wikipedia.org/wiki/Tagged_pointer
[src-immix]: https://gitlab.com/inko-lang/inko/tree/master/vm/src/immix
[src-gc]: https://gitlab.com/inko-lang/inko/tree/master/vm/src/gc
