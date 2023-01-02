---
author: Yorick Peterse
title: "Inko in 2023"
date: 2023-01-02 16:00:00 UTC
---

It's been a while since our last update, so let's take a look at what's planned
for Inko in 2023.

## Table of contents
{:.no_toc}

* TOC
{:toc}

## Compiling to machine code

In the [0.10.0 release post](/news/inko-0-10-0-released/) I mentioned that I was
looking into the possibility of compiling Inko to machine code instead of
virtual machine (VM) bytecode. Since then I've been working on implementing
this, and I'm pleased to report that we've made a lot of progress in recent
weeks.

### Why compile to machine code?

The obvious question here is "Why?". Well, there are several reasons for this.

The first reason is performance: while Inko is not aiming to be a low-level
language with the best performance one can imagine, I do want it to perform well
enough for most scenarios. Using an interpreter makes this difficult, as a pure
interpreter can only go so fast, requiring a Just In Time (JIT) compiler to
improve performance further. JIT compilers are notoriously difficult to
implement, and come with a variety of drawbacks such as the warm-up time,
maintenance complexity, and more. If your name is Cliff Click or Mike Pall you
might be able to produce a competitive JIT, but I'm not convinced I'm able to do
so.

The second reason is portability. Compiling to VM bytecode means you only need
to compile your program once, which is great, but it also complicates the
process of distribution. For example, if your program uses shared libraries
through Inko's FFI then you either need to bundle these somehow, or require the
user to have these installed. The VM also needs to be installed in every
environment you're deploying to. Of course we could come up with a solution
similar to Java's JAR files and allow you to bundle shared libraries in such an
archive, but it's yet another tool/feature we'd have to develop and maintain. In
contrast, if we compile to machine code we can just statically link the
libraries (including the C standard library), and no interpreter is needed
either.

The third reason is to make Inko more competitive. Many well established
interpreted languages already exist, and competing with these is difficult.
While there are also many languages that compile to machine code, I feel there
are more opportunities, in particular for languages that try to better balance
compile times and runtime performance. Go is probably the best example of such a
language: its runtime performance may not be as good as say Rust or C, but in
exchange you get fast compile times, good support for concurrency, and much
more. As it turns out, a lot of developers are looking for just such a language.

### What backend is used by the compiler?

For the backend I looked into three options: [LLVM](https://llvm.org/),
[Cranelift](https://github.com/bytecodealliance/wasmtime/tree/main/cranelift),
or C.

I decided not to go with C for several reasons:

- Providing good debugging support is tricky, as you'd be debugging the
  generated C code, and this code would be anything but readable.
- There's a _ton_ of undefined behaviour you'd have to take care of. Even
  something as simple as signed integer arithmetic relies on undefined behaviour
  for overflows. I just don't feel comfortable compiling to a language where
  it's so easy to shoot yourself in the foot.
- For such cases you might be able to use compiler-specific functions, but not
  all compilers provide the same functions. For example, gcc and clang both have
  functions for checked signed integer arithmetic, but
  [tcc](https://en.wikipedia.org/wiki/Tiny_C_Compiler) lacks such functions,
  requiring you to implement them yourself.
- C doesn't give you enough control over the generated machine code. For
  example, if you need custom function prologues (e.g. to dynamically grow the
  stack), there's no cross-compiler/platform way of doing so.

Cranelift initially seemed like a promising backend: it's written in Rust,
focuses on fast code generation, and the API didn't seem too difficult.
Unfortunately, Cranelift suffers from several issues that make it unsuitable at
this time:

- The documentation is sorely lacking. Several Markdown documents provide a
  high-level overview of what Cranelift is, and while API documentation exists,
  it's often not made clear what you should use and when, or what the purpose is
  of a function (e.g. the documentation often just describes the function
  signature).
- Integers use wrapping upon overflow, but there are no functions for generating
  checked arithmetic. If I'm not mistaken, the [Cranelift backend for
  Rust](https://github.com/bjorn3/rustc_codegen_cranelift) ends up implementing
  this itself. While in this particular case that might have been an option,
  there may be other cases where this isn't as easy.
- Cranelift itself doesn't provide optimisations, instead you have to implement
  all those yourself. This isn't necessarily a bad thing, but having at least
  _some_ optimisations available would make my life easier.
- As far as I understand, Cranelift is mostly developed/supported by the
  developers of [Wasmtime](https://wasmtime.dev/). Should this company shut
  down, it's not clear how well maintained Cranelift would be, and I don't have
  the resources to maintain both a programming language and a code generator.
- Cranelift's API is spread across various libraries, including third-party ones
  for generating object files and debug information (at least from what I
  remember). This also means the documentation is spread around, making it
  difficult to get a better understanding of what to use (e.g. for generating
  debug information). For example: I still don't know what the idiomatic way is
  of generating debug information for your generated code, even though I looked
  into this extensively.
- Last I checked, debug information support in general was spotty, and I
  vaguely recall it not being supported on all platforms Cranelift supports.

In summary: Cranelift is a promising library, but it's not mature enough for
Inko's needs.

Which brings me to LLVM. LLVM has pretty much everything you need, from a vast
API to well written (if not at times somewhat dense) documentation, lots of user
guides and tutorials, support for a ton of platforms, and [decent bindings for
Rust](https://github.com/TheDan64/inkwell). Of course LLVM isn't perfect, and
suffers from two problems:

1. LLVM versions don't always provide good backwards compatibility, and OS' and
   distributions don't always provide the same versions. For example, Debian
   ships LLVM 11.0.1, Fedora ships 15.0.0, and Arch Linux ships whatever the
   latest version is. Some distributions provide packages for each major
   version, others don't.
1. LLVM is slow, or at least slower than desired.

We can deal with both these problems though: as (if) Inko gets more popular,
more distributions/OS' are likely to include it into their repositories,
removing the need for compiling the compiler from source. We can also provide
our own repositories/packages where necessary.

LLVM being slow is something we can deal with by having it process less code
(e.g. by doing more work ourselves before lowering to LLVM), and by making the
compiler parallel and/or incremental.

In summary: LLVM has everything we need right now, and thus seemed like the
most sensible choice.

### What state is the compiler in?

The compiler is able to compile a small subset of Inko to machine code. A lot of
important parts are still missing though, such as method calls, spawning
processes, and more. If I had to guess, I'd say we're at about 30% completion.

It's worth mentioning that our goal for the next release is to have a working
compiler, but not necessarily a good or complete compiler. For example,
everything that isn't crucial for running Inko programs (e.g. debug information
and optimisations) won't be implemented for now. I might also consider dropping
support for Windows temporarily, as the new runtime doesn't work on Windows and
I'm not familiar enough with it to get it to work.

### Will you still use Rust?

Yes. The compiler is written in Rust, and this will remain to be the case for
the foreseeable future. Inko's runtime is also written in Rust, and is statically
linked to the generated machine code. The runtime provides various core
functions (e.g. for memory allocations and spawning processes), the scheduler,
and platform specific code to allow for efficient switching of processes.

## A package manager for Inko

Inko's `master` branch contains a package manager for Inko, using Git
repositories as a way of distributing packages. At the moment this is a separate
executable, but once the LLVM-based compiler is complete we'll integrate this
into the `inko` executable. You can find some details on the upcoming package
manager in [this merge
request](https://gitlab.com/inko-lang/inko/-/merge_requests/125) and [this guide
in the
documentation](https://docs.inko-lang.org/manual/master/getting-started/modules/#using-ipm).

## Building a community around Inko

In 2022 I mostly focused on the technical side of Inko, such as implementing its
new memory management strategy. In 2023 I want to focus more on also building a
community around Inko.

A first step already taken was switching from Matrix to Discord (though we still
have a Matrix bridge). Discord makes moderation much easier, in particular
across channels (something absent in Matrix when using spaces or separate
channels). We used to bridge the Matrix channel to the [/r/ProgrammingLanguages
Discord](https://discord.com/invite/yqWzmkV), and most of the people chatting
came from this Discord, so switching to Discord made the most sense.

Something I'm still looking into is to stream and/or record videos on the work
I'm doing. I'm not sure about this just yet as the idea terrifies me, but
I hope I can convince myself it won't be that bad. The format would likely be
20-30 minute videos going over specific topics, rather than recording a three
hour programming session, as I feel the former is more useful and easier to
digest.

## More funding

With the community growing I also hope to receive more funding through
donations. While I've set aside enough money to continue for the foreseeable
future, I (unfortunately) don't have infinite wealth.

As for what specific steps to take to improve upon this, I'm not sure yet. I'm
hoping that with a growing community there will also be an increase in funding,
but only time will tell.

## The next release

At this point it's difficult to say when the next release of Inko is available,
as there's still a lot of work to do one the new LLVM backend, but I'm hoping
for a new release around March.

## Following and supporting Inko

If Inko sounds like an interesting project, consider joining the [Discord
server](https://discord.gg/seeURxHxCb) or the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org). You can also follow along
on the [/r/inko subreddit](https://www.reddit.com/r/inko/). If you'd like to
financially support Inko, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
