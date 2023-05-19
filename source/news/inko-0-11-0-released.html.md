---
author: Yorick Peterse
title: "Inko 0.11.0 released"
date: 2023-05-19 00:03:04 UTC
---

After nine months of hard work we're pleased to announce the release of Inko
0.11.0, replacing the bytecode interpreter with a native code compiler using
[LLVM](https://llvm.org/).

## Table of contents
{:.no_toc}

* TOC
{:toc}

## What is Inko?

In case you're new to Inko and wondering what Inko is: Inko is a language for
building concurrent software with confidence. This means that it should be easy
to write concurrent (without race conditions!) and memory safe programs, whether
you're used to a low-level language such as C or Rust, or a high-level language
such as Python or Erlang.

Inko is useful for all sorts of applications, such as HTTP servers, command-line
applications, databases, static site generators, and more.

For more information, check out the website and the
[Inko manual](https://docs.inko-lang.org).

## Compiling to machine code

Before 0.11.0, Inko used a custom bytecode interpreter written in Rust. In this
release, the interpreter is replaced with a native code compiler using LLVM as
its backend. The result is much better performance (at least once we start
implementing optimisations). Distributing applications is also made easier, as
you no longer need to install the interpreter in your deployment environments,
and any C libraries used can be statically linked into the native code:

```
$ cat ~/Downloads/test.inko
import std::stdio::STDOUT

class async Main {
  fn async main {
    STDOUT.new.print('Hello, world!')
  }
}

$ inko build --release --output /tmp/test ~/Downloads/test.inko

$ file /tmp/test
/tmp/test: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[xxHash]=9dd11e347ca9a03e, with debug_info, not stripped

$ /tmp/test
Hello, world!
```

Using native code also makes it possible to reuse many existing tools to analyse
and debug your Inko programs, such as [Heaptrack](https://github.com/KDE/heaptrack),
[perf](https://perf.wiki.kernel.org/index.php/Main_Page),
[bloaty](https://github.com/google/bloaty), [GDB](https://sourceware.org/gdb/),
and more. Debugging support is still limited (e.g. you can't print variables in
GDB), but we'll improve this over time. For example, using bloaty we can see
what contributes to the size of an executable:

```
$ bloaty /tmp/test -d compileunits
    FILE SIZE        VM SIZE
 --------------  --------------
  44.5%  3.23Mi  17.6%   455Ki    library/std/src/lib.rs/@/std.04582a2c-cgu.0
  30.0%  2.18Mi  41.7%  1.05Mi    library/core/src/lib.rs/@/core.2ea223d9-cgu.0
   4.4%   330Ki   7.6%   196Ki    [66 Others]
   3.1%   232Ki   9.0%   232Ki    [section .text]
 ...
```

As part of this work we also investigated using
[Cranelift](https://github.com/bytecodealliance/wasmtime/tree/main/cranelift) as
a backend, and implemented a decent amount of our backend using Cranelift.
Ultimately we decided against this as the project isn't mature and stable enough
for our needs.

Due to LLVM being quite slow, our long-term vision is to implement as many
optimisations ourselves before lowering to LLVM, thus reducing the amount of
work it needs to perform and keeping compile times fast.

There's still a lot of work to do on the compiler, such as reducing code sizes,
[improving how generics are
compiled](https://github.com/inko-lang/inko/issues/525), fixing various bugs,
and more. In other words, what is available today is a good start, but we still
have a long way to go.

## Windows is no longer supported

This release drops support for Windows, as supporting Windows proved to
difficult. Supporting Windows has always been difficult as we aren't familiar
with Windows as a development platform, but the new runtime library the native
code links against proved to difficult to get working on Windows. Windows isn't
the kind of platform we'd expect developers to deploy Inko software to either.

In other words, supporting Windows came at a high cost but didn't bring any
benefits. Rather than delaying the release and complicating future work, we
opted to remove Windows support entirely for the foreseeable future. At some
point in the future we may reconsider supporting Windows, but it will require
somebody to maintain the necessary changes, as we unfortunately aren't able to
do so.

## Futures are replaced with channels

Inko no longer uses futures when sending messages and awaiting their results,
and support for synchronous messages (basically syntax sugar for sending a
message and awaiting the result right away) is removed. Instead, channels can be
used if a message needs to send its output somewhere. For example, instead of
this:

```inko
class async Example {
  fn async example(value: Int) -> Int {
    value * value
  }
}

class async Main {
  fn async main {
    let ex = Example {}
    let fut = async ex.example(4)

    fut.await # => 16
  }
}
```

You now write this:

```inko
class async Example {
  fn async example(value: Int, output: Channel[Int]) {
    output.send(value * value)
  }
}

class async Main {
  fn async main {
    let out = Channel.new(size: 1)
    let ex = Example {}

    ex.example(4, out)
    out.receive # => 16
  }
}
```

For simple cases this is a little more verbose, but it makes bi-directional
communication between processes much easier compared to the old approach.
Channels are multiple-producer multiple-consumer channels, and messages are
processed in FIFO order. The current implementation is probably not the most
performant due to the use of locking, but this is something we can improve in
the future.

## The FFI is temporarily removed

Inko's interpreter used [libffi](https://sourceware.org/libffi/) to interact
with C code. As part of working on the native code compiler we looked into
providing a type-safe FFI (see
[this issue](https://github.com/inko-lang/inko/issues/290) for more details),
but determined that implementing this would delay the release considerably. As
such, this release removes the old FFI but doesn't include a new FFI. Our plan
is to introduce a new FFI (and conditional compilation) in the coming months,
and include that in the next release.

## Package management

Inko now includes a package manager, available using the `inko pkg` subcommand.
Our implementation is based on that of [Futhark](https://futhark-lang.org/),
which in turn bases it on Go. Version selection is performed using [minimal
version selection](https://research.swtch.com/vgo-mvs), greatly simplifying the
implementation and its performance.

Packages are just Git repositories hosted on GitHub, GitLab.com, or other
platforms. This removes the need for a central package hosting service, which
would be too costly and time consuming to operate.

For more information, refer to the documentation of [modules and
packages](https://docs.inko-lang.org/manual/main/getting-started/modules/).

## A new type checker

This release includes a new type checker. The new implementation is simpler,
easier to test, fixes various bugs the old type checker suffered from, better
handles cyclic types, and includes various improvements to the type inference
algorithm.

As part of this work, support for `Self` types is removed as this proved to
complicate the type checker and compiler too much, and was the source for
various bugs.

## A new process scheduler

The process scheduler has been rewritten from the ground up. This new scheduler
is 25-30% faster compared to the old one, and the implementation is simpler and
easier to understand.

Blocking operations (such as reading files) are handled better. Instead of using
a fixed-size pool of threads for blocking operations and moving processes
between this pool and the regular pool, threads that take too long to perform
blocking work are automatically replaced with a back thread that continues the
rest of its work. When the thread finishes the blocking operation, it becomes a
backup thread, and the cycle repeats itself. This approach removes the need for
first moving processes between thread pools, improving the performance of
blocking operations.

Handling of network IO is also improved: instead of a single thread polling
sockets for readiness, Inko supports multiple threads (though it still defaults
to just one). This improves performance for programs that have _a lot_ of
sockets that need to be polled by epoll/kqueue/etc.

## Throwing is replaced with algebraic data types

Inko used a form of checked exceptions for error handling. This has been
replaced with the use of algebraic data types such as the new `Result` type.
This makes composing errors much easier, and simplifies the implementation of
iterators. The `try` and `throw` keywords still exist and serve as syntax sugar
to make error handling a little easier. For example, instead of this:

```inko
let thing = match result {
  case Ok(val) -> val
  case Error(err) -> return Result.Error(err)
}
```

You can just write this:

```inko
let thing = try result
```

And instead of this:

```inko
return Result.Error('oh no!')
```

You can write this:

```inko
throw 'oh no!'
```

Performance wise the new setup is a little slower as `Result` is heap allocated,
but this is something we'll improve in the future.

You can find some more details on the error handling changes in [this
issue](https://github.com/inko-lang/inko/issues/362).

## Additions to the standard library

The standard library includes new features, such as the module `std::json` for
parsing and generating JSON, methods for stripping values from strings such as
leading spaces, support for various cryptographic hash functions (all
implemented in Inko) such as SHA1 and ChaCha20, and more. For example, here's
how you'd use the new cryptography modules to create a hash using SHA256:

```inko
import std::stdio::STDOUT
import std::crypto::sha2::Sha256

class async Main {
  fn async main {
    let hasher = Sha256.new
    let output = STDOUT.new

    hasher.write('hello!'.to_byte_array)

    # This prints "ce06092fb948d9ffac7d1a376e404b26b7575bcc11ee05a4615fef4fec3a308b"
    # to STDOUT.
    output.print(hasher.finish.to_string)
  }
}
```

If you just want to hash a single value instead of a stream, you can also write
the following:

```inko
import std::stdio::STDOUT
import std::crypto::sha2::Sha256

class async Main {
  fn async main {
    let output = STDOUT.new

    output.print(Sha256.hash('hello!'.to_byte_array).to_string)
  }
}
```

## What's next

In the coming months we'll focus on providing a new [FFI and API for conditional
compilation](https://github.com/inko-lang/inko/issues/524),
[cross-compilation](https://github.com/inko-lang/inko/issues/524), [a better way
to compile generic types and
methods](https://github.com/inko-lang/inko/issues/525), and more. For a full
list of the work planned, take a look at the [0.12.0
milestone](https://github.com/inko-lang/inko/milestone/21).

## Following and supporting Inko

If Inko sounds like an interesting project, consider joining the [Discord
channel](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

We are working on Inko full-time and using our savings to cover the costs. If
you'd like to support the continued development of Inko, please consider
donating using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse).
Every donation, no matter how small, is greatly appreciated.
