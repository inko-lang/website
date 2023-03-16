---
author: Yorick Peterse
title: Inko 0.3.0 released
date: "2018-11-24 20:00:00 UTC"
description: Inko 0.3.0 has been released
---
<!-- vale off -->

Inko 0.3.0 has been released.

<!-- READ MORE -->

## Noteworthy changes in 0.3.0
{:.no_toc}

* TOC
{:toc}

The full list of changes can be found in the [CHANGELOG][changelog].

In the [0.2.4][0.2.4 release] release post we announced that for 0.3.0 we would
be working towards supporting network operations, such as opening TCP sockets.
Due to it still not being entirely clear how we will implement this, we decided
to postpone this until at least 0.4.0.

### Foreign Function Interface

Support for interfacing with C code is now possible using Inko's new Foreign
Function Interface (FFI). The FFI is available using the module `std:ffi`. For
example, we can use `floor()` from the C standard library as follows:

```inko
import std::ffi::Library
import std::ffi::types
import std::stdio::stdout

# Library.new is used to open a C library, using one or more names or paths to
# find the library.
let libm = Library.new(['libm.so.6'])

# Using `libm.function` here we attach the `floor()` function. The type `f64`
# translates to the C `double` type.
let floor = libm.function('floor', [types.f64], types.f64)

# Sending `call` to `floor` will execute the function. Since the return type is
# `Dynamic`, we have to cast it to `Float` ourselves.
let number = floor.call(1.1234) as Float

stdout.print(number)
```

We can also use C structures. For example, here is how we would use
`gettimeofday()` in Inko:

```inko
import std::ffi::(self, Library, Pointer)
import std::ffi::types
import std::stdio::stdout

let libc = Library.new(['libc.so.6'])

# int gettimeofday(void*, void*)
let gettimeofday = libc
  .function('gettimeofday', [types.pointer, types.pointer], types.i32)

# void* malloc(size_t)
let malloc = libc.function('malloc', [types.size_t], types.pointer)

# free(void*)
let free = libc.function('free', [types.pointer], types.void)

# This defines a structure similar to the following C code:
#
#     struct timeval {
#         time_t tv_sec;
#         suseconds_t tv_usec;
#     }
#
# The exact type used (i64, i32, etc) may differ per platform.
let timeval = ffi.struct do (struct) {
  struct['tv_sec'] = types.i64
  struct['tv_usec'] = types.i64
}

# Since `malloc.call` returns a `Dynamic`, we need to cast it to a `Pointer`
# ourselves.
let time_pointer = malloc.call(timeval.size) as Pointer

gettimeofday.call(time_pointer, Pointer.null)

# This will wrap the pointer in an instance of our `timeval` structure defined
# earlier.
let time_struct = timeval.from_pointer(time_pointer)

# We can read the values of a structure by sending `[]` to it. To write a value
# we would use `[]=`.
stdout.print(time_struct['tv_sec'] as Integer)

# Now that we're done we can release the memory of the structure.
free.call(time_pointer)
```

The Foreign Function Interface does come with some limitations. Most notably:

1. Variadic functions (such as `printf()`) are not supported at the moment.
1. Using Inko blocks as callbacks for C functions is not supported. This means
   that currently it's not possible to use C libraries that make use of
   callbacks, such as [libuv](https://libuv.org/).

Variadic functions will almost certainly be supported in the future, but right
now they are not a big priority. C callbacks are unlikely to be supported any
time soon due to the complexity involved. For example, Inko processes can be
suspended at various points in time for a variety of reasons. This means we need
to somehow deal with this when this happens when calling back into Inko from C.
Since we do not yet have solutions for these problems, we decided not to support
calling back into Inko from C at this time.

For more information, refer to the source code of [std::ffi][std-ffi].

### Process Pinning

Certain C functions use thread-local storage. For example, GUI libraries
typically require that all operations are performed on the same thread that
initialised the GUI. To support this, Inko now allows pinning of processes to OS
threads. Pinning a process will result in two things happening:

1. The process will always run on the same OS thread.
1. The OS thread will _only_ run the process that was pinned.

To pin a process, use `std::process.pinned`:

```inko
import std::process

process.pinned {
  # All code in this block will be pinned to the current OS thread.
}
```

Because the OS thread will _only_ run the pinned process, pinning processes
should only be used when _absolutely_ necessary. For example, say you have 8
threads, 8 pinned processes, and 2 unpinned processes. If the pinned processes
are pinned before the unpinned processes start, the unpinned processes will
never run as there are no threads available for them to run on.

### Seconds are now the base unit for timeouts

The `std::process` module provided various methods that support timeouts. For
example, `std::process.receive` allows you to specify the number of seconds
after which this method should return:

```inko
import std::process

process.receive(100) # Wait for at most 100 milliseconds.
```

Starting with 0.3.0, the base unit used is now seconds instead of milliseconds.
This means that the above code on 0.3.0 will result in the process being
suspended for at most 100 seconds, instead of 100 milliseconds. To suspend for
at most 100 milliseconds in 0.3.0, we need to write the following:

```inko
import std::process

process.receive(0.1) # Wait for at most 0.1 seconds, or 100 milliseconds.
```

This change applies to the following methods:

* `std::process.receive_if`
* `std::process.receive`
* `std::process.suspend`
* `std::process::Receiver.receive`

### More specific platform names

The method `std::os.platform` now returns more specific platform names. Prior to
0.3.0, it would return one of the following values:

* other
* unix
* windows

As of 0.3.0, the following values can be returned:

* android
* bitrig
* dragonfly
* freebsd
* ios
* linux
* macos
* netbsd
* openbsd
* unix
* unknown
* windows

### VM instruction changes

A variety of virtual machine instructions have been changed or merged together.
For example, the various instructions for obtaining object prototypes
(`GetIntegerPrototype`, `GetFloatPrototype`, etc) were merged together into the
`GetPrototype` instruction. Other instructions, such as `ProcessSpawn` and
`ProcessSuspendCurrent` take different types of values as their arguments.

### musl executables are no longer provided

Up until 0.3.0, Inko provided executables of the VM that used
[musl](https://www.musl-libc.org/). These executables were more portable, as
they did not dynamically link to the system's C standard library (e.g. GNU
libc).  Unfortunately, musl does not support `dlopen()`, which is required to
support Inko's FFI. This meant we had one of two options:

1. Continue providing musl executables, but without support for Inko's FFI.
1. Stop providing musl executables altogether.

Option one would most likely result in a lot of confusion, especially since ienv
preferred to install musl executables over regular ones. It also didn't quite
feel right to provide a build of Inko that doesn't support all of its features.
Because of this, we decided to stop providing musl executables. This means that
from 0.3.0 on, all executables will dynamically link to the system's C standard
library, and ienv will no longer prefer to install musl executables over regular
ones.

[changelog]: https://github.com/inko-lang/inko/blob/v0.3.0/CHANGELOG.md#030---november-25-2018
[std-ffi]: https://github.com/inko-lang/inko/blob/7dc4d1c3b1f91640eb9861dc507314e3ed1e86fd/runtime/src/std/ffi.inko
[0.2.4 release]: /news/inko-0-2-4-released/
