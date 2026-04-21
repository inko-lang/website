---
{
  "title": "Inko 0.20.0: reducing heap allocations by 50%",
  "date": "2026-04-22"
}
---

We're pleased to announce the release of Inko 0.20.0. This release includes
support for escape analysis to drastically reduce heap allocations, structured
logging, atomically reference counted types, better method inlining, and a lot
more.

If you're new to Inko: Inko is a programming language for building concurrent
software, but without the usual headaches such as data race conditions and
non-deterministic garbage collectors. Inko features deterministic automatic
memory management, compiles to machine code using LLVM, supports different
platforms (Linux, macOS and FreeBSD, and potentially any other Unix based
platform), and is easy to get started with. For more information, refer to the
[homepage](/) or the [manual](https://docs.inko-lang.org/manual/v0.20.0/).

While not directly related to this release (but enabled by the code that went
into it), we're also pleased to announce that our website and release artifacts
are now served by Inko itself (instead of Cloudflare), using
[shost](https://github.com/yorickpeterse/shost) as the HTTP server (and without
a reverse proxy such as Nginx).

## [Table of contents]{toc-ignore}

::: toc
:::

This release includes _a lot_ of changes not included in this announcement. For
the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.20.0/CHANGELOG.md#0200-2026-04-20).

A special thanks to the following people for contributing changes included in
this release:

- [Tomoki Aonuma](https://github.com/uasi)
- [Jonathan Hult](https://github.com/jhult/)
- [John R. Durand](https://github.com/mortax)

## Reducing heap allocations using escape analysis

In Inko types are defined using the `type` keyword, for example:

```inko
type Person {
  let @name: String
  let @age: Int
}
```

Instances of such types are allocated on the heap using `malloc()`. To create a
type that is allocated on the stack instead, one must use `type inline` like so:

```inko
type inline Person {
  let @name: String
  let @age: Int
}
```

Inline types come with some [restrictions and
caveats](https://docs.inko-lang.org/manual/v0.20.0/getting-started/types/#inline-types)
that mean you might not always be able to use them. Most notably, `inline` types
only allow assigning fields new values when done using an _owned_ reference and
not a (mutable) borrow.

Inko 0.20.0 introduces an implementation of inter-procedural escape analysis
performed during the inlining pass. This optimization looks at heap allocated
values and determines if they escape their allocated scope or not. If they don't
escape the allocation is "promoted" to the stack, removing the need for dynamic
memory allocation at runtime for these values.

The implementation is inter-procedural meaning that the compiler looks at the
program as a whole, instead of processing methods in isolation. This allows for
more fine-grained analysis, such as when dealing with method calls that aren't
inlined. For example, if a method call isn't inlined but its arguments are
flagged as "won't escape" then heap values passed as the arguments may still be
promoted to the stack.

The inliner looks at all method calls in a program and processes them in reverse
topological order, using [Tarjan's strongly connected
components](https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm)
algorithm. This means that if method `A` calls method `B`, `B` is processed
before `A`. Escape analysis runs as part of this traversal so that we don't need
to perform it twice, and so that callers can use the escape analysis results of
their callees whenever necessary.

Escape analysis has traditionally been applied to more dynamic languages such as
Java, and in more recent years Go. The improvements tend to be modest:
somewhere between 10% to 20% on average (with an occasional outlier) based on
various papers we looked at (and assuming our understanding is correct):

- [MEA2: A Lightweight Field-Sensitive Escape Analysis with Points-to Calculation for Golang](https://dl.acm.org/doi/10.1145/3689759): 10% on average
- [Escape from Escape Analysis of Golang](https://dl.acm.org/doi/abs/10.1145/3377813.3381368): 10% on average as well
- [Escape Analysis for Java](https://faculty.cc.gatech.edu/~harrold/6340/cs6340_fall2009/Readings/choi99escape.pdf): somewhere between 10% and 20%
- [Escape Analysis for the Glasgow Haskell Compiler](https://pp.ipd.kit.edu/uploads/publikationen/scheper22masterarbeit.pdf): 14%

For Inko the implementation is much more effective, with an average of 50% of
heap allocated values that are promoted to stack allocated values. This average
is based on the escape analysis statistics of the following projects:

- [shost](https://github.com/yorickpeterse/shost): an HTTP server for hosting
  static websites
- [OpenFlow](https://github.com/yorickpeterse/openflow): a central ventilation
  control system
- [kvi](https://github.com/yorickpeterse/kvi): a simple key-value database
- [idoc](https://github.com/inko-lang/idoc): Inko's documentation generator
- [wtml](https://github.com/yorickpeterse/wtml): a simple program for processing
  bank statements from [ING](https://www.ing.nl/)

For these projects the percentage of heap values promoted to stack values are as
follows:

|=
| Project
| Promoted
| Escaping
|-
| shost
| 58%
| 42%
|-
| OpenFlow
| 51%
| 49%
|-
| kvi
| 50%
| 50%
|-
| idoc
| 47%
| 53%
|-
| wtml
| 54%
| 46%

These numbers are produced by running `inko build --release --escape-stats` for
each project. Of course these numbers will differ between projects but an
average of 50% is a promising start, and there are plenty of ways the inlining
and escape analysis passes can be improved upon in the future.

## Better inlining of closures

Before 0.20.0 if a method that received a closure argument was inlined then
calling the closure (using the `call` method) would still result in an indirect
call, and that call wouldn't be inlined further. For example, this code:

```inko
fn foo {
  bar(fn { 10 })
}

fn bar(closure: fn -> Int) {
  closure.call
}
```

Would be inlined into this:

```inko
fn foo {
  let closure = fn { 10 }

  closure.call
}
```

As part of the work on implementing escape analysis we also improved the
inlining of closure calls, and of course closures themselves are also promoted
to stack allocated values where possible. The result is that for the above
example the `call` call would be inlined, resulting in essentially something
like this:

```inko
fn foo {
  let closure = fn { 10 }

  10
}
```

[Future optimizations](https://github.com/inko-lang/inko/issues/971) may be
applied to further optimize the closure away entirely whenever possible.

## Better handling of recursive methods when inlining

To ensure the method inliner doesn't get stuck in an infinite loop trying to
inline recursive methods, the inliner uses Tarjan's strongly connected
components algorithm and doesn't inline method calls that are recursive.

This release includes several fixes for cases where the inliner would still get
stuck and a fix for a bug that would prevent callees of recursive methods from
being inlined into their callers.

## Structured logging

This release introduces the
[`std.log`](https://docs.inko-lang.org/std/v0.20.0/module/std/log/) module in
the standard library for structured logging of wide events, based on the
findings of articles such as [Logging sucks](https://loggingsucks.com/) and
[Using Canonical Log Lines for Online
Visibility](https://brandur.org/canonical-log-lines). Instead of logging
arbitrary text that nobody ever looks at and consumes tons of storage space, you
log fewer but _wider_ (= more fields) _events_. An event is not arbitrary text
such as "The user failed to log in" but something you can query/search for with
ease, such as `user_login_failed` or `http_request`. For example,
[shost](https://github.com/yorickpeterse/shost) produces logs such as the
following (using JSON as its output format):

```json
{
  "time": "2026-04-21T16:39:44.398Z",
  "name": "http_request",
  "fields": {
    "address": "::ffff:XXX.XXX.XXX.XXX",
    "method": "GET",
    "host": "yorickpeterse.com",
    "path": "/feed.xml",
    "version": "1.1",
    "user-agent": "CommaFeed/5.3.4 (https://github.com/Athou/commafeed)",
    "status": 304
  }
}
```

Getting started with the `std.log` module is easy:

```inko
import std.log (Logger)

type async Main {
  fn async main {
    let logger = Logger.text

    logger.event('example').with('name', 'Alice').with('age', 42).submit
  }
}
```

This produces the following output:

```
2026-04-21T16:44:07.557Z example name="Alice" age=42
```

Formatting log output is done asynchronously such that the cost for log
producers remains consistent, regardless of how complex the output format is or
where it's sent to (STDOUT, an external service, etc).

For more details refer to the documentation of the `std.log` module.

## Immutable and atomically reference counted types

Inko takes a shared-nothing approach to concurrency: processes are isolated from
each other and can't share memory, instead memory is _moved_ between processes.
Sometimes you _do_ have to share data, and sometimes using a process to access
the data is too expensive.

This is where Inko's new atomically reference counted types come in. Such types
are defined using `type ref`:

```inko
type ref Person {
  let @name: String
  let @age: Int
}
```

Such types use atomic reference counting and are considered value types. This
means the following is valid, which wouldn't be the case for regular types:

```inko
let a = Person(name: 'Alice', age: 42)
let b = a

a.name # => 'Alice'
b.name # => 'Alice'
```

These types are immutable, so you can't assign fields new values or mutate them
in-place. In addition, they may only store other `ref` or `copy` types (e.g.
`Int`).

The standard library introduces two new types that build upon this new feature
and use atomic operations:

- [`AtomicBool`](https://docs.inko-lang.org/std/v0.20.0/module/std/sync/AtomicBool/)
- [`AtomicInt`](https://docs.inko-lang.org/std/v0.20.0/module/std/sync/AtomicInt/)

Both types use acquire and release semantics for their atomic operations, such
as for storing a new value. These new types are useful when you need some degree
of synchronisation across processes and the cost of sending messages between
these processes is deemed too high.

## Compressing and decompressing data using gzip

This release introduces the new standard library module
[`std.compress.gzip`](https://docs.inko-lang.org/std/v0.20.0/module/std/compress/gzip/)
that adds support for compressing and decompressing gzip streams. For example,
compressing data is done as follows:

```inko
import std.compress.gzip (Encoder)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let enc = Encoder.new(Stdout.new)

    enc.write('hello world').or_panic
    enc.finish.or_panic
  }
}
```

In addition, the method [`std.net.http.server.compress_response`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/http/server/compress_response/)
allows for compressing of HTTP responses.

The implementation of gzip is built on top of the libz-rs-sys crate from the
[zlib-rs](https://github.com/trifectatechfoundation/zlib-rs) project, a pure
Rust implementation of the zlib API. This crate is included in Inko's runtime
library such that no extra C dependencies are required.

## Easier generating of JSON

This release includes a new set of methods and types for generating JSON:

- [`std.json.Json.array`](https://docs.inko-lang.org/std/v0.20.0/module/std/json/Json/#method.array)
- [`std.json.Json.object`](https://docs.inko-lang.org/std/v0.20.0/module/std/json/Json/#method.object)
- [`std.json.ObjectBuilder`](https://docs.inko-lang.org/std/v0.20.0/module/std/json/ObjectBuilder/)
- [`std.json.ArrayBuilder`](https://docs.inko-lang.org/std/v0.20.0/module/std/json/ArrayBuilder/)

For example, instead of writing this:

```inko
import std.json (Json)

type async Main {
  fn async main {
    let map = Map.new

    map.set('name', Json.String('Alice'))
    map.set('age', Json.Int(42))

    Json.Object(map).to_string
  }
}
```

You can now write this instead:

```inko
import std.json (Json)

type async Main {
  fn async main {
    Json.object.string('name', 'Alice').int('age', 42).into_string
  }
}
```

## Portable API for interrupting accepting of connections

This release [introduces a new
API](https://github.com/inko-lang/inko/commit/2e74d40f166cb74ea34a1e8c5118fd461703626d)
for interrupting calls to `TcpServer.accept`. In Inko 0.19.1 this was achieved
by cloning a `TcpServer`, sending it to another process and then calling
`shutdown` on the socket. Unfortunately this doesn't work on macOS, meaning it
was impossible to interrupt such calls, such as when an HTTP server should shut
down in response to a signal.

Using the new API involves three steps:

1. Create a [`TcpServer`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/socket/TcpServer/) using
   [`TcpServer.new`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/socket/TcpServer/#method.new)
1. Get a [`Notifier`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/socket/Notifier/)
   using [`TcpServer.notifier`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/socket/TcpServer/#method.notifier)
1. Call [`Notifier.notify`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/socket/Notifier/#method.notify)
   to interrupt the corresponding `TcpServer`

Internally the new API uses a pipe for sending and receiving the notification,
and the system's polling mechanism (e.g. epoll) to wait for either a new
connection or a notification. Most important of all, this new API works across
all platforms supported by Inko.

## Improved memory usage for String

The `String` type's layout used to be the following:

```
╭──────────────────────────╮
│ Object header   16 bytes │
├──────────────────────────┤
│ Size             8 bytes │
├──────────────────────────┤       ╭────────────────────────╮
│ Bytes pointer    8 bytes │ ────> │ String value   N bytes │
╰──────────────────────────╯       ╰────────────────────────╯
```

This meant that allocating a `String` required at least 32 bytes of space and
two allocations: one for its contents, and one for the container.

Inko 0.20.0 instead uses the following layout:

```
╭───────────────────────────╮
│ Size              8 bytes │
├───────────────────────────┤
│ References        4 bytes │
├───────────────────────────┤
│ heap/stack flag   1 byte  │
├───────────────────────────┤
│ String value      N bytes │
╰───────────────────────────╯
```

That is, there's only a single value that needs to be allocated and it embeds
both the meta data such as the size _and_ the string contents. This means a
`String` only needs a single allocation and its minimum size is reduced from 32
bytes to 16 bytes.

## Improved performance for parsing HTTP headers and methods

This release includes performance optimizations for
[`std.net.http`](https://docs.inko-lang.org/std/v0.20.0/module/std/net/http/)
for [parsing HTTP headers](https://github.com/inko-lang/inko/commit/b2f2c08c1dc4f90525540d968510aeca5f5841b1)
and [HTTP methods](https://github.com/inko-lang/inko/commit/a5fbf4e908b1028fb3658445cbf146ec3ac308b4),
improving performance by 2.2x and 2x respectively.

## Improved process scheduler performance

This release includes various performance improvements for the process
scheduler, such as:

- [Defer waking up threads for scheduling processes](Defer waking up threads for scheduling processes)
- [Reuse process stacks (again)](https://github.com/inko-lang/inko/commit/fc7a7827566c59a42a14b838c90b9e83de55c9f2)
- [Reserve a small amount of space for mailboxes](https://github.com/inko-lang/inko/commit/eb91f814b041bb67129329e023928bce68b1a453)
- [Only notify timeout threads when necessary](https://github.com/inko-lang/inko/commit/017aea435e87fa2ee67e213c47f482f02e6efe8c)

The need for these improvements arose after migrating the Inko website from
Cloudflare to Hetzner and using [shost](https://github.com/yorickpeterse/shost)
(written in Inko) to host the website, as doing so [revealed various performance
bottlenecks in the scheduler](https://github.com/inko-lang/inko/issues/953).

## Fixed static linking when using Zig as the linker

Thanks to Jonathan Hult, static linking when using Zig as the linker [now
works](https://github.com/inko-lang/inko/commit/21d29134d77dd12ce047202d4886211b651f272e)
as Zig doesn't support the `-l:libX.a` we used for statically linking C
libraries.

## When generating new projects, the `inko-` prefix is removed

Thanks to Tomoki Aonuma, generating a project using `inko init` [now strips the
`inko-` prefix (if present) from the
name](https://github.com/inko-lang/inko/commit/f63552fa80f96755d50389375bfaa9c410748c23).
This way running `inko init inko-foo` results in a `foo/` directory containing
the project, instead of it creating an `inko-foo/` directory.

## Getting the sign of an Int

Thanks to John R. Durand it's [now possible to get the
sign](https://github.com/inko-lang/inko/commit/e0b55c0dd71fd9073caf59307bba812122cd836e)
of an `Int` using [`Int.sign`](https://docs.inko-lang.org/std/v0.20.0/module/std/int/Int/#method.sign).

## Rust 1.85 is now required

Starting with Inko 0.20.0, compiling the compiler and runtime library requires
Rust 1.85 or newer. Rust 1.85 was released in February 2025 and is widely
available across many platforms, so this shouldn't pose a problem.

## UIntN types are now called UintN

For FFI purposes various C unsigned integer types are available. These types
used the format `UIntN` where `N` is the number of bits: `UInt8`, `UInt32`, etc.

In Inko 0.20.0 these types are renamed to use the format `UintN`, so `Uint8` and
`Uint32` for example.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb) or star the [project on
GitHub](https://github.com/inko-lang/inko). You can also subscribe to the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

Development of Inko is self-funded, but this isn't sustainable. If you'd like to
support the development of Inko and can spare $5/month, _please_ become a
[GitHub sponsor](https://github.com/sponsors/YorickPeterse) as this allows us to
continue working on Inko full-time.
