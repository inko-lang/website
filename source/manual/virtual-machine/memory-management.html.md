---
title: Memory management
---

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

The allocator allocates memory in 32 KB blocks of aligned memory. This means
that allocating an object for the first time will result in a 32 KB block being
assigned to the process performing the allocation. Objects are allocated into
these blocks using bump allocation.

## Garbage collector

The garbage collector is a parallel, generational garbage collector. Multiple
processes can be collected in parallel, and for every process its call stack is
processed in parallel as well.

A process can not run while it is being garbage collected, but _only_ the
process to garbage collect will be suspended, while all others can continue to
run as normal.

There are two types of garbage collectors in Inko:

1. A process-local garbage collector.
1. A mailbox garbage collector.

The process-local garbage collector will perform garbage collection for the heap
of a process, while the mailbox collector will _only_ garbage collect a process'
mailbox. Both are garbage collected independently, but they can not be garbage
collected at the same time for the same process.

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

IVM solves this by finalising such structures in a cooperative manner. At the
end of a garbage collection cycle, the garbage collector will schedule blocks
for finalisation if they have objects that need to be finalised. Which objects
require finalisation is stored in a byte map. Finalising blocks is done in a
separate thread pool.

Because finalisation happens separately, it's possible that an allocator may try
to allocate an object into an object slot that is being finalised. When this
happens, the allocator will try to first finalise _all_ objects pending
finalisation, then allocate the object. Finalising all pending objects means the
first allocation may take a little longer, but also ensures that future
allocations in the same block can be performed as fast as possible. The pseudo
code for this roughly comes down to the following:

```rust
if is_finalizing() {
  finalize_pending()
}

allocate()
```

The `is_finalizing()` routine uses an atomic boolean to determine if
finalisation is necessary, removing the need for always having to use a more
expensive mutex or spinlock:

```rust
// We load the boolean using LLVM's "Acquire" atomic ordering.
finalizing.load(Ordering::Acquire)
```

The `finalize_pending()` routine is roughly implemented as follows:

```rust
let lock = acquire_finalization_lock()

// It's possible the garbage collector finalised our block in the mean time. If
// this is the case we'll just go back to allocating the object.
if !is_finalizing() {
  return
}

for object in current_block.objects() {
  // Objects that have to be finalised have an entry set in a dedicated bitmap.
  if should_finalize_object(object) {
    // Here we deallocate the "value" the object wraps, such as a socket.
    deallocate(object.value)

    // Now that the object is finalised, we remove its entry from the bitmap.
    remove_from_finalize_bitmap(object)
  }
}

// Now that we have finalised the block we can update the atomic boolean, using
// the "Release" ordering.
finalizing_boolean.store(false, Ordering::Release)

// Once we're done we unlock our lock. In Rust this is done for us automatically
// once it goes out of scope.
unlock(lock)
```

We call this cooperative finalisation, because both the garbage collector and
allocator will cooperatively finalise objects. In most cases the garbage
collector will finalize all objects before a block is used again.

Finalisation is not exposed to the language, instead it's a system used to
reclaim memory of certain data structures (sockets, file handles, and so on),
without having to do this during a garbage collection cycle.

The VM guarantees that any object that needs to be finalised will eventually be
finalised. However, the VM does not guarantee _when_ this will happen. This
means you don't have to (for example) close a file handle, though it is strongly
recommended you do so as soon as you no longer need the object. These guarantees
may be broken due to a bug, so it's best to not rely on them too much.

### Prefetching

The garbage collector uses [data prefetching][data-prefetching] when tracing
through live objects, based on the paper ["Effective Prefetch for Mark-Sweep
Garbage Collection"][prefetching-paper]. This can improve performance of tracing
live objects by up to 30% in the best case, compared to not using prefetching.

## Process heaps

Each process has two heaps: the process heap, and the mailbox heap. The process
heap is where objects for your program are allocated into. The mailbox heap is
used for storing received messages. These messages are copied to the process
heap when using the `ProcessReceive` instruction. This removes the need for
synchronising access to the process heap, at the cost of requiring slightly more
memory.

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

The prototype field is a tagged pointer, which can has the lower two bits set as
follows:

| Lower two bits | Meaning
|:---------------|:-------------------------------------------------------------
| `00`           | The field contains a regular pointer to the prototype.
| `10`           | The field is a forwarding pointer that should be resolved.

Encoding this data directly into the attributes saves us an extra 8 bytes of
memory per object.

The attributes field is a pointer to a HashMap, using FNV as the algorithm.
These maps are 24 bytes in size, and they are only allocated when necessary.

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
[data-prefetching]: https://en.wikipedia.org/wiki/Cache_prefetching
[prefetching-paper]: http://users.cecs.anu.edu.au/~steveb/downloads/pdf/pf-ismm-2007.pdf
