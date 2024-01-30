---
{
  "title": "Inko progress report: October 2019",
  "date": "2019-11-04 16:46:15 UTC"
}
---

The progress report for October 2019 is here! In October we spent a lot of time
improving the garbage collector, and resolving various bugs we found in the
garbage collector.

We started October by continuing the work on the compiler, but we discovered
some bugs in Inko's garbage collector. These bugs were severe enough that we
could not postpone fixing them. While investigating these bugs we discovered
that some parts of Inko's garbage collector were not implemented properly
(unrelated to the bugs we found). This combined resulted in us dedicating
October to resolving these issues, as well as applying some improvements to the
garbage collector in various places.

## [Table of contents]{toc-ignore}

::: toc
:::

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/). If you would like to
donate via other means, please contact us through Email or GitHub.

If you would like to engage with others interested in the development of Inko,
please join the [Matrix chat
channel](https://riot.im/app/#/room/#inko-lang:matrix.org). You can also follow
the development on [Reddit](https://www.reddit.com/r/inko/), or follow the
author of Inko on [Twitter](https://archive.is/6LWOm). For more
information check out the [Community](/community) page.

## Donate using GitHub Sponsors

In October we got accepting into [GitHub
Sponsors](https://help.github.com/en/github/supporting-the-open-source-community-with-github-sponsors/about-github-sponsors).
This allows you to donate money directly via GitHub. You can donate using [this
link](https://github.com/sponsors/YorickPeterse/).

## A better remembered set

Let's start with the bug that we ran into: sometimes objects would end up
changing their type. For example, an object that was originally an array would
end up being a string; but only after several garbage collection cycles took
place. Such a problem is caused by the garbage collector not finding all live
objects, and the allocator later reusing the memory of these objects.

Inko's garbage collector is a generational collector, and it uses a data
structure called a "remembered set" to record mature objects that contain
pointers to young objects. When writing a young pointer to a mature object, a
piece of code runs called a "write barrier". This barrier ensures that when we
write a young pointer to a mature object, we remember the mature object. When we
run a young garbage collection, we also trace the mature objects that have been
remembered, ensuring that any young pointers we find along the way are marked
and traced.

This brings us to the problem: when the garbage collector promoted an object to
the mature generation, it did not add this promoted object to the remembered
set. As long as the young pointers are directly reachable this is not a problem,
but if they are only reachable through a mature object the young objects would
be garbage collected:

![Unreachable young object](/images/october-2019-progress-report/unreachable_young_object.svg)

Here we would not be able to find the young object in a young collection, as we
would never trace the mature object.

To solve this we had to change the garbage collector to remember mature objects.
This introduced three new problems:

1. We were using a hash set as the remembered set, but without synchronising
   access to it. This is fine at runtime as the set is not modified
   concurrently, but during garbage collection we may have multiple threads
   promoting (and thus remembering) objects.
1. When moving remembered objects we would corrupt the hash set. Moving objects
   involves updating pointers to these objects, but the hash set would reuse
   hashed values of the old pointers after an update. This meant that moved
   objects could not always be retrieved from the remembered set.
1. When promoting objects we would end up adding a lot of objects to the
   remembered set, even if an object does not contain any young pointers. This
   slows down young collections, as we have to trace the entire remembered set
   on every young collection.

We solved these problems by using a different data structure, and by only
remembering mature objects if they contain young pointers. For the data
structure we use a "chunked list": a linked list of fixed size arrays. By using
a chunked list we never need to copy and resize the array when adding new
values, something that can be expensive when this involves copying lots of
values. Our chunked list supports concurrent additions to the list, allowing
multiple collector threads to remember objects concurrently. Since we do not
rely on hashing we can also update any pointers in this list, without corrupting
it in some way.

To prevent remembering objects that don't contain any young pointers, we use a
specialised trace procedure for promoted objects. After promoting an object we
trace it using this procedure. If we encounter any young pointers directly
stored in the promoted object, we remember it. After tracing we schedule all the
pointers found for the regular tracing procedure. This approach is
straightforward, and looks a bit like the following pseudo-code:

```rust
fn promote(object) {
    let promoted = promote(object);
    let mut remember = false;

    for pointer in promoted.pointers() {
        if pointer.is_young() {
            remember = true;
        }

        trace(pointer);
    }

    if remember {
        remember_object(promoted);
    }
}
```

Using this approach we can drastically reduce the size of the remembered set,
and ensure that young collections are not slowed down as objects are promoted to
the mature generation. Applying all these techniques allowed us to solve the
three problems mentioned above, which in turn prevents objects from being
garbage collected prematurely.

## Inko now requires a 64 bits architecture

To prevent remembering an object multiple times we store a bit in the object
whenever it's remembered (by tagging a pointer). On 32 bits architectures the
lower two bits of a pointer are always zero, and on a 64 bits architecture the
lower three bits are zero.

For every object we already set aside two bits used during garbage collection,
but for this we needed a third one. Refactoring our code to allow for this would
require a lot of work, so instead we opted to use the third lower bit on a
pointer that we were already tagging. This change requires that a 64 bits
architecture is used, so starting with the next release Inko requires a 64 bits
architecture.

## Evacuating of objects during garbage collecting

To combat fragmentation, the garbage collector "evacuates" objects. When a block
of memory containing objects is deemed as fragmented, we move its objects into
another block. Determining if evacuating is necessary involves calculating some
statistics at the start of a garbage collecting cycle, and by looking at the
statistics of the last collection.

When looking into the problems with our remembered set, we found a bug in our
implementation: we mark blocks as fragmented based on these statistics, but we
would only calculate the statistics is there were one or more fragmented blocks.
This meant that in practise we would never evacuate. This wasn't always the
case, as in the past we would also consider other criteria to determine if
evacuating was needed, but this was removed at some point.

This problem has now been fixed, and evacuating is now performed if the previous
garbage collection did not free up enough blocks of memory. In the future we may
adjust this further to reduce the amount of collections that evacuate objects,
but for now this should suffice.

## Reducing memory usage of process mailboxes

Inko uses message passing to allow processes to communicate. When sending a
message, it's deep copied into the target process (unless a process sends a
message to itself). Messages were allocated into heap separate from the regular
process heap, allowing the receiving process to run while receiving messages;
without the need for locking. The downside of this approach is that receiving a
message involves two copies:

1. When sending the message we first copy it into the mailbox heap.
1. When receiving the message we copy it into the process heap.

These two steps were performed to ensure a process never directly refers to a
message on the mailbox heap, making it possible to collect the two separately.

Some time ago we made various improvements to the allocator to allow for
concurrent object allocations. This allows the collector to more efficiently
promote and evacuate objects, and to only use a lock when acquiring a new
block of memory from the global allocator.

We now take advantage of support for concurrent allocations. When sending a
message, we first lock a (spin)lock in the mailbox. Once locked we copy the
message directly into the receiving process' heap. The process receiving the
message can continue running while this happening. When garbage collecting a
process we first lock the same (spin)lock, ensuring no objects are allocated by
a sending process while the receiving process is being garbage collected.

This new setup removes the need for a separate mailbox heap and drastically
simplifies the implementation of our garbage collector. The allocator overhead
of always using the concurrent allocation strategy is negligible, and certainly
is far less of a problem than the memory overhead and code complexity of the old
approach.

A drawback of this approach is that a sending process (and thus OS thread) may
be blocked if the receiving process is being garbage collected. We can optimise
this by rescheduling the sending process if the lock could not be obtained, but
for the sake of simplicity we have not implemented this yet.

## Reduced parallelism for improved performance

It may sound a bit odd, but to improve performance of the garbage collector we
now perform certain steps sequentially instead of in parallel. Specifically,
when preparing garbage collection of a process and reclaiming unused blocks we
would perform work in parallel on a per block basis. We used the excellent
[Rayon](https://github.com/rayon-rs/rayon) library for this.

Measuring the performance of these steps showed that the setup and
synchronisation overhead of Rayon was great enough to outweigh the benefits,
even when processing a large heap. The exact timing difference will vary based
on the amount of live objects, but we found that removing the use of Rayon
consistently improved garbage collection timings by around 500 microseconds.
That may not sound like much, but for small heaps that can be as much as a third
of the total garbage collection time.

## Improved parallelism for tracing objects

While we have not implemented this yet, we are working towards improving the
tracing of live objects by making better use of all CPU cores. At the moment we
only trace stack frames in parallel. This is beneficial when you have a large
call stack with a similar number of reachable pointers per frame, but it does
not improve performance much when the amount of pointers is unbalanced. For
example, if one frame contained thousands of pointers we would only use a single
thread to trace those pointers.

Our plan is to schedule pointers in batches (instead of one by one), then
process these batches in parallel. This would allow for greater parallelism,
without the cost of scheduling work becoming too expensive. Much of the code for
this is already in place, as we need it for scheduling and running processes; we
just need to adapt it for tracing objects. We hope to finish this in November.

## Improved performance for checking for empty blocks of memory

We have improved performance of checking if a block of memory contains any live
objects or not. This may not sound exciting, but Inko's garbage collector
performs such checks quite often, meaning any improvement is more than welcome.
The implementation is more interesting than it may sound, so let's dive in!

The garbage collector maintains two byte maps used while tracing objects: a
byte map used for marking objects, and a byte map for marking lines. Objects are
marked so that we know when to stop tracing live objects. Lines are marked so we
know when an object is empty, which chunks of memory can be reused, and to
calculate some garbage collection statistics. We use bytes instead of bits since
the maps are modified concurrently, and this is easier (and faster) to use when
using bytes compared to using bits.

Checking if a block is empty is an important step in the garbage collection
process, and is done by examining the line byte map to see if there are any
marked entries. If so, the block is not empty. A naive approach of performing
such a check may involve a simple `for` loop that terminates the moment we find
a marked entry:

```rust
fn is_empty(&self) -> bool {
    for value in self.values.iter() {
        if *value == 1 {
            return false;
        }
    }

    true
}
```

While simple to implement, this function can end up taking quite a bit of time.
In our case each line map consists of 64 entries. In the worst case only the
last entry is marked (= has a value of `1`), requiring a total of 64 checks.

Since we store bytes and not bites we can optimise this by reading one _word_ at
a time, instead of one _byte_ at a time. On a 64 bits architecture this means we
would only need 8 checks, as here one word equals 8 bytes. Reading a word at a
time is straightforward to implement in Rust, though it does require a bit of
unsafe code:

```rust
use std::mem;

fn is_empty(&self) -> bool {
    let mut offset = 0;

    while offset < self.values.len() {
        let value = unsafe {
            let ptr = self.values.as_ptr().add(offset) as *const usize;

            *ptr
        };

        if value > 0 {
            return false;
        }

        // This increments the offset by the size of a word (usize always has
        // the size of a single word in Rust).
        offset += mem::size_of::<usize>();
    }

    true
}
```

The block of `unsafe` code is needed to get a pointer to our byte map values and
calculate the right offset to read from. The use of `if value > 0` instead of
`if value == 1` is not a mistake. When we read an entire word at a time, the
values we get may be unpredictable. For example:

|=
| Sequence of bytes to read
| Resulting integer
|-
| `0, 0, 0, 1, 0, 0, 0, 0`
| `16 777 216`
|-
| `0, 0, 0, 1, 0, 0, 0, 1`
| `72 057 594 054 705 152`

Regardless of the value produced: if a word contained at least one byte set to
1, the value produced will be greater than 0; hence we check if the produced
value is greater than zero.

We measured the performance of both the old and new approach using
[Criterion](https://github.com/bheisler/criterion.rs), a benchmarking library
for Rust. For both tests we created a byte map with 256 entries, and set entry
255 to 1. The old approach takes just under 140 nanoseconds to check if the byte
map is empty, while the new approach only takes 8 nanoseconds. This means the
new approach is almost 18 times faster than the old approach.

We might be able to further improve this using
[SIMD](https://en.wikipedia.org/wiki/SIMD), but there are four problems with
this approach:

1. Rust stable only offers low-level SIMD functions, requiring you to figure out
   yourself which ones are supported by your platform.
1. The largest vector type SIMD (at least when using Rust) has to offer is a
   vector with 64 values, and we need a vector with 256 values for object byte
   maps.
1. More user-friendly libraries such as
   [packed\_simd](https://github.com/rust-lang/packed_simd) require the use of
   Rust nightly. We could add optional support for SIMD when Rust nightly is
   used, but this leads to two different code paths, making it harder to
   maintain Inko.
1. Byte maps are modified concurrently during garbage collection, and SIMD
   vectors do not support this as far as we are aware of.

For these reasons we won't be using SIMD for the time being.

## Plans for November

For November we want to finish work on improving parallel performance of the
garbage collector, then get back to working on the self-hosting compiler.
