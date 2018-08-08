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

### Object aging

Each generation is divided into one or more "buckets", each bucket contains
objects all of the same age. The age of a bucket is just a signed integer,
ranging from -3 to 3. Instead of copying objects to new buckets upon surviving a
garbage collection cycle, the age of the entire bucket is incremented. When a
bucket reaches the maximum age (3), all of its live objects are moved to the
mature generation. New objects are always allocated into the bucket with age 0,
which is known as the eden space.

In this setup, we only need to copy objects when promoting them to the mature
generation, instead of having to do this every time they age.

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
happens, the allocator will try to first finalise the object, then allocate the
object. We call this cooperative finalisation, because both the garbage
collector and allocator will cooperatively finalise objects. In most cases the
garbage collector will finalize all objects before a block is used again.

Finalisation is not exposed to the language, instead it's a system used to
reclaim memory of certain data structures (sockets, file handles, and so on),
without having to do this during a garbage collection cycle.

The VM guarantees that any object that needs to be finalised will eventually be
finalised. However, the VM does not guarantee _when_ this will happen. This
means you don't have to (for example) close a file handle, though it is strongly
recommended you do so as soon as you no longer need the object. These guarantees
may be broken due to a bug, so it's best to not rely on them too much.

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
so on.

While this particular setup requires some extra indirection (instead of
embedding certain values directly), it drastically simplifies the allocator and
garbage collector, as all objects are of an identical size.

## Sending messages

When sending a message from one process to another, the message is deep copied.
The following types are optimised for this:

Strings use reference counting under the hoods. This means that sending a
message results in the reference count being incremented, instead of the entire
string being copied.

Integers that are small enough to fit in a pointer are not heap allocated, thus
copying these will be as cheap as just creating a copy of a pointer.

[immix]: http://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf
