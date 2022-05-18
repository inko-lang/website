---
author: Yorick Peterse
title: The challenge of building a Foreign Function Interface
date: 2018-12-21 12:00:00 UTC
keywords:
  - ffi
  - foreign function interface
  - programming language
description: >
  An overview of the challenges faced when building a Foreign Function
  Interface.
---
<!-- vale off -->

In [Inko 0.3.0][inko 0.3.0] we introduced a Foreign Function Interface for
interfacing with C. In this article we'll take a look at the challenges faced
when building a Foreign Function Interface.

<!-- READ MORE -->

A Foreign Function Interface (FFI) is a mechanism for one programming language
to make use of another programming language, usually C. Most programming
languages out there offer such an interface, such as (but not limited to):
Python, Ruby, Rust, Lua, and Inko itself. Such an interface is necessary as
there is a lot of software written in C, and rewriting all that in a different
programming language is not doable.

To provide an FFI, most programming languages will use one (or sometimes both)
of the following approaches:

1. By allowing developers to write extensions in C, which are then loaded into
   the program.
1. By using [libffi][libffi]: a software library that allows you to call C
   functions, using information defined at run time instead of at compile time.

Both of these approaches have their benefits and drawbacks. C extensions usually
have little overhead, though this may vary between programming languages. A
drawback of this approach is that you'll have to write your code in C, which
isn't exactly the easiest language to deal with.

Using libffi means you can write all your code in the target language, such as
Ruby. This comes at the cost of overhead, as some extra work might be necessary
to convert types and execute function calls. For example, a Ruby integer has to
be converted to an `unsigned int` in C, including some validation to make sure
the integer would not overflow. A Just-in-time (JIT) compiler might be able to
optimise this away, but at its core the use of libffi does introduce some
overhead.

## Type conversion and validation

Regardless of what approach for an FFI we take, we may need to convert some
types of our host language (e.g. Ruby) to types in the target language (e.g. C).
The most straightforward example would be the conversion of integral types. In a
language that has different types for integers of different sizes, such as most
compiled languages, this is less of an issue.

For a language with only a single (often arbitrary precision) integer type (such
as Ruby and Python) things will get more tricky. In such a language you can not
pass your integer to C, as its value may not be compatible with the expected
type. For example, passing the number `300` to a C `char` is likely to break the
program. This means some form of runtime validation and conversion might be
necessary. You could decide to not validate the value and instead cast it to the
target type, requiring developers to make sure they are passing the right value.

For more complex types such as structures or strings, things may get more
tricky. For example, in C a string is a sequence of bytes that ends with a NULL
byte, but in many languages it's a more complex type. In Rust the `String` type
is a structure consisting out of at least two fields:

1. A pointer to the bytes of the string, _without_ a NULL byte.
1. A single [word][word] (`usize` in Rust) that stores the number of bytes in
   the string.

Such complex types can not be converted to a C `char*`, nor can we pass the
pointer to the string as it is not NULL terminated. Rust's approach to this
problem is to provide separate types for C strings: `CStr` and `CString`. It is
then up to the programmer to somehow construct these types, which may require
copying the memory of the source string so the NULL byte can be added to it.

In Inko we instead use a custom string structure called `ImmutableString`
(strings are immutable in Inko). Like Rust's `String` type, `ImmutableString`
stores the number of bytes separate from the pointer to the bytes. Unlike the
`String` type, it also adds a NULL byte at the end of every string. This NULL
byte is ignored by all string operations. When passing an `ImmutableString` to
C, we simply take the pointer to the underlying bytes and pass that to C. This
removes the need for copying the entire string, at the cost of having to store
one extra byte of memory to store the NULL byte.

How a language decides to handle type conversion and validation can have a big
impact on performance, and as such a language may decide to not perform any
validation at all. Inko is one such language: when you pass an integer type to
C, Inko will cast it to the appropriate C type without performing any
validation. For integers this will result in the values wrapping around, which
may result in a program misbehaving. This approach means that well written
programs will not suffer from the overhead of having to validate every integer
passed to C.

## Multitasking

The approach to multitasking employed by a programming language can affect the
implementation of an FFI. Most languages use cooperative multitasking, meaning
the language will not suspend a task; unless the task requests for this to
happen. In a language using pre-emptive multitasking, a task might be suspended
by the language for a variety of reasons. Examples of such languages are Erlang
and Inko.

Pre-emptive languages have some sort of scheduler that decides what OS thread a
task runs on, and the language may decide to move the task to a different OS
thread at some point. This poses a problem when interfacing with C: when calling
into C, the OS thread the task runs on will be unable to perform other work
until the C call finishes. If the pre-emptive language uses a fixed number of OS
threads to perform its work (known as "M:N scheduling"), this can result in all
OS threads being used for blocking C calls, leaving no room for other tasks to
run.

Another problem for pre-emptive languages is thread-local storage. A C function
might require the presence of data stored in thread-local storage. If a task can
be moved across OS threads, this could result in the C function failing. To
prevent this from happening, your language would have to offer some way of
pinning a task to an OS thread. In Inko you can do this by using the method
`pinned` from the `std::process` module:

```inko
import std::process

process.pinned {
  # Everything inside this closure will always execute on the same OS thread,
  # and no other tasks can be executed on that OS thread.
}
```

Programmers would then have to use this method in the appropriate places
whenever interfacing with C code that uses thread-local storage.

Most cooperative languages run tasks on their own OS threads, meaning they do
not have to deal with these problems. This is referred to as "1:1 scheduling".
Instead, they will have their own problems to deal with. Depending on the
underlying platform a OS process may only be able to start a limited number of
OS threads, and starting OS threads might be expensive.

For Inko we experimented with moving to a model where every Inko process is
mapped directly to an OS thread, instead of processes running on a fixed pool of
OS threads. While using a 1:1 scheduler allowed us to remove quite a bit of code
(around 2000 lines), in the few (limited) tests we ran the performance was
actually worse compared to using an M:N scheduler. It also didn't simplify
interfacing with C as much as we hoped for. As a result, we decided to keep the
M:N scheduler for the time being.

## C callbacks

Various C libraries make use of callbacks: C functions that are called at some
later point. Various GUI libraries make heavy use of callbacks, but they are
also used by other libraries such as [libuv][libuv]. These libraries usually use
some kind of event loop that runs in a single OS thread, which is usually
started using a C call that doesn't return until the program terminates.

This setup poses a problem for pre-emptive languages. If we want to execute the
callback in the context of the task that registered it, we need to somehow make
sure we don't start unwinding the call stack too far when the callback finishes.

To illustrate this, let's say we have task A which sets up a callback, then
starts the event loop using a blocking C call. Now imagine the call stack would
be as follows:

    foo()
      bar()
        event_loop()

When the callback gets executed, the call stack would turn into the following:

    foo()
      bar()
        event_loop()
          callback()

When returning from the callback (denoted as `callback()`), we need to make sure
to not also start returning from `event_loop()`, `bar()`, and `foo()`, as doing
so could break the program. How exactly this would be handled and how
complicated this would be depends on the implementation of the programming
languages.

In case of Inko, this is difficult enough to deal with that C callbacks simply
are not supported at this time. Due to the implementation of the virtual
machine, supporting C callbacks would require some sort of flag to be stored for
every stack frame. This flag could then be used to determine if we have to keep
unwinding after a return, or if we should only unwind from the most recent call
frame. This however requires extra memory and bookkeeping, even when most of the
time the flag would never be used.

If a language uses garbage collection, C callbacks pose another problem: as long
as the C callback is registered, any objects visible to the callback need to be
kept around. If the garbage collector is not aware of a C callback capturing any
objects, it may end up garbage collecting them. This means that either the
garbage collector needs to somehow have access to the callback so it can be
scanned for objects, or the objects visible to the callback need to be pinned
somehow. This isn't just limited to C callbacks: the moment an object is stored
in memory managed by C, the garbage collector somehow has to be made aware of
this. Regardless of the solution a language may decide to use, it's likely to
prove quite difficult.

C callbacks may seem like they are easy to support, but depending on the type of
language and its implementation, it may prove to be quite the challenge. Add
garbage collection to the mix, and it might end up being difficult to support C
callbacks.

## C standard library differences

Different operating systems and compilers may implement the C standard library
(libc) in slightly different ways. For example, for error handling many
functions use the `errno` thread-local variable. In many implementations `errno`
isn't actually a variable, instead it's a macro. For glibc `errno` is defined as
follows:

```c
extern int *__errno_location (void) __THROW __attribute_const__;
# define errno (*__errno_location ())
```

Other implementations of libc may decide to use different names for the
`__errno_location` function, such as Mac OS which uses the name `__error`.

This isn't just limited to the `errno` variable. For some libc implementations,
certain structures may have additional fields. One such example is the `tm`
structure used by functions such as `localtime()`, which in glibc contains some
additional fields.

If a language wishes to provide bindings to libc, it needs to take care of all
these differences. This in turn could require a substantial amount of work. An
alternative would be to add bindings to libc in a third-party library, but this
may result in many libraries trying to provide libc bindings at varying levels
of completeness.

## Type safety

Languages may wish to provide some form of type safety when using an FFI. For
dynamically typed languages this would require some form of runtime validation,
while statically typed languages may be able to perform this at compile time.
Compile time validation would likely require dedicated syntax for binding to
external code, to make it easier for the compiler to understand things. For
example, in Rust you can bind to a C function using an `extern` block:

```rust
use std::ffi::c_void;

extern "C" {
    fn malloc(amount: usize) -> *mut c_void
}

malloc(4)
```

This allows the Rust compiler to then verify calls to `malloc()` as if it were
defined as a regular Rust function.

For more dynamic languages this might be difficult. In Ruby for example you
would write the following to bind `malloc()` to the language:

```ruby
require 'fiddle'

# This dynamically loads libc.
libc = Fiddle.dlopen('libc.so.6')

malloc = Fiddle::Function
  .new(libc['malloc'], [Fiddle::TYPE_SIZE_T], Fiddle::TYPE_VOIDP)

# This is the equivalent of `malloc(4)` in C.
malloc.call(4)
```

If for a moment we were to assume Ruby was statically typed, the compiler would
not have sufficient information to determine how exactly `malloc()` can be used.
To allow validating of calls to `malloc()`, the compiler would have to have
special understanding of how `Fiddle::Function.new` binds a function. It would
then also have to know that `Fiddle::TYPE_SIZE_T` maps to the C `size_t` type,
and that `Fiddle::TYPE_VOIDP` maps to the C `void*` type. For a language as
dynamic as Ruby this would likely be impossible to implement in a reliable way.

Inko currently suffers from the same problem, as the FFI works in a similar way.
Inko's equivalent of the above example would be the following:


```inko
import std::ffi::Library
import std::ffi::types

# This dynamically loads libc.
let libc = Library.new(['libc.so.6'])

let malloc = libc.function('malloc', [types.size_t], types.pointer)

# This is the equivalent of `malloc(4)` in C.
malloc.call(4)
```

Because defining and binding of the C function happens at runtime, the Inko
compiler has no way verifying calls to `malloc()`. This means that
`malloc.call('foo')` would not result in any compile time errors, instead
producing a runtime error.

If a language wishes to provide type safety for its FFI, a special syntax for
binding C to the language will most likely be required. This syntax would have
to also support some form of conditionals, allowing the developer to handle
differences between different library implementations and operating systems.
Adding such syntax may complicate the language more, both for the maintainers
and its users. Maintainers will have to extend the compiler to make use of this
syntax, and developers need to learn and remember it. This might not be a
problem for all languages, but it is definitely something one should take into
account when designing an FFI.

## Loading of libraries

When building an FFI, there are two ways one could load a third-party library
into their program:

1. Statically or dynamically linking the library at compile time.
1. Dynamically loading the library at runtime using `dlopen()` or an equivalent
   routine.

Static and/or dynamically linking the library is a popular technique for
compiled languages, while dynamically loading the library is a popular choice
for interpreted languages. Ruby and Python both use dynamic loading for example.

Both approaches come with their own benefits and drawbacks. Loading a library at
compile time is something that is possible on pretty much every platform out
there, but it doesn't work for interpreted languages. Dynamic loading on the
other hand works for both compiled and interpreted languages, but might not be
available on all platforms. For example, [musl][musl] doesn't support dynamic
loading of library when linked statically, and defines `dlopen()` as a stub:

```c
#include <dlfcn.h>
#include "dynlink.h"

static void *stub_dlopen(const char *file, int mode)
{
	__dl_seterr("Dynamic loading not supported");
	return 0;
}

weak_alias(stub_dlopen, dlopen);
```

For Inko this proved quite problematic. Up until we added support for FFI, we
provided VM builds that linked to musl, making them more portable.
Unfortunately, with the introducing of the FFI we had to stop providing these
builds as they would not be able to support the FFI.

Languages wishing to use dynamic loading need to take into account that
`dlopen()` or similar routines may not be available depending on what
implementation of libc is being used. This will likely force them to dynamically
link to the libc implementation, resulting in an executable that might not work
across different versions of the libc implementation.

## The design of the FFI itself

The design of the FFI can be a challenge as well. A good FFI is implemented in
such a way that it looks somewhat like C, making it more natural and
easier to build bindings. One approach some FFIs take is to process C header
files and generate the necessary bindings based on these headers. This removes
the need for developers to manually write their bindings, at the cost of
potentially being less flexible. This does come at the cost of having to parse C
header files, and unfortunately the C syntax is rather complex. This can get
even worse if you also want to support parsing C++ header files.

For Inko we went with an API similar to the one provided by Ruby, which in turn
is fairly similar to the APIs provided by other languages. Generating bindings
based on C headers is something we believe is best handled by a third-party
library, reducing the amount of dependencies that may be necessary to use the
language.

## Conclusion

Building an FFI for C is no easy task. There are many challenges to overcome,
and the implementation of a language and the corresponding FFI may result in
certain functionality not being available. A well designed FFI may be
straightforward to use, but it's implementation is likely far from
straightforward.

Those interested in providing an FFI for their own language may find [Inko's
implementation][inko ffi] of use. Inko uses [libffi][libffi], and the FFI layer
(excluding the various VM instructions that expose the FFI) is about 780 lines
of Rust.

[inko 0.3.0]: https://inko-lang.org/news/inko-0-3-0-released/
[libffi]: https://sourceware.org/libffi/
[word]: https://en.wikipedia.org/wiki/Word_(computer_architecture)
[macos thread limit]: https://www.jstorimer.com/blogs/workingwithcode/7970125-how-many-threads-is-too-many
[libuv]: https://libuv.org/
[musl]: https://www.musl-libc.org/
[inko ffi]: https://gitlab.com/inko-lang/inko/blob/57247e719ebd937f5fff7dbb9fcfc90fed5be858/vm/src/ffi.rs
