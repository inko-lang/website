---
{
  "title": "Inko 0.17.0 released",
  "date": "2024-10-28T17:00:00Z"
}
---

We're pleased to announce the release of Inko 0.17.0. This release includes
support for inlining method calls, changes to built-in concurrency types,
support for working with CSV files, and more.

## [Table of contents]{toc-ignore}

::: toc
:::

For the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.17.0/CHANGELOG.md#0170-2024-10-28).

A special thanks to the following people for contributing changes included in
this release:

- [Ryan Frame][rjframe]

## Inlining of method calls

This release introduces support for inlining method calls. Inlining allows
eliminating the cost of the method call, and enables the application of other
(future) optimizations. Method calls are inlined when meeting one of the
following conditions:

- The method is determined to be small enough using a heuristic.
- The method is defined using the `inline` keyword.

The exact heuristic used is unspecified and subject to change. The heuristic is
used to determine a rough size estimate of a method, which is then used to
determine if there's room left to inline a method into its caller. The current
threshold applied to each method is on the conservative end as we've yet to
include optimizations that take advantage of inlining, but this is likely to
change in the future.

If a method is defined using the `inline` keyword, it's _always_ inlined
regardless of its size, _unless_ the method is a recursive method. This keyword
is used by the various operator methods (e.g. `Int.+`) to ensure they're always
inlined, resulting in them compiling to simple machine instructions instead of
requiring a method call.

After inlining method calls, the compiler checks for methods that are now no
longer called and removes them. This ensures that if a method is inlined into
all its call sites, it isn't included in the final executable.

Inlining is enabled by default, and disabled when using `inko build --opt=none`.

You can read more about inlining and the other optimizations the compiler
applies in the new [Compiler
optimizations](https://docs.inko-lang.org/manual/v0.17.0/references/optimizations/)
page in the manual.

## Futures, Promises and Channels

In [0.11.0](http://localhost:8000/news/inko-0-11-0-released/) the use of the
`Future` type was replaced with a `Channel` type. In 0.17.0, futures are
re-introduced but in a different and much better way. The new setup consists of
two types: [`Future`](https://docs.inko-lang.org/std/v0.17.0/module/std/sync/Future/)
and [`Promise`](https://docs.inko-lang.org/std/v0.17.0/module/std/sync/Promise/).

A `Future` is used to read a value produced asynchronously while a `Promise` is
used to write the value. Writing to a `Promise` or reading from a `Future`
takes over ownership of the value and thus one can do so only once. When reading
from a `Future`, the calling process is suspended until a value is available:

```inko
import std.sync (Future)

class async Main {
  fn async main {
    match Future.new {
      case (future, promise) -> {
        promise.set('hello')
        future.get # => "hello"
      }
    }
  }
}
```

The [`Channel`](https://docs.inko-lang.org/std/v0.17.0/module/std/sync/Channel/)
type still exists but is no longer a type provided by the runtime library,
instead it's built on top of the new `Future` and `Promise` types and backed by
an Inko process:

```inko
import std.sync (Channel)

class async Main {
  fn async main {
    let chan = Channel.new

    chan.send('hello')
    chan.receive # => "hello"
  }
}
```

In this new setup, the `Future` and `Promise` types are the main types to
communicate results back to the process that sent a message. The `Channel` type
in turn is meant for cases where you have many `Future` values you want to
resolve and you don't want to wait for _all_ of them to be resolved before
moving on.

The new `Future` and `Promise` types are implemented entirely in Inko, instead
of relying on Rust functions provided by the runtime library. This means they
support all types, including those that are not the size of a word, something
the old `Channel` type didn't support.

## New implementations for various IO APIs

Various IO APIs, such as those provided by the `std.fs.file` and
`std.net.socket` modules are now implemented entirely in Inko, instead of
relying on functions provided by the runtime library written in Rust. For
example, `std.fs.file.ReadOnlyFile` was implemented on top of Rust's `File`
type, but is now written entirely in Inko.

This change gives us greater control over the implementations of these APIs and
ensures Rust semantics/behaviours won't leak into Inko. In certain cases this
also results in a more efficient implementation.

Refer to the following issues for more details:

- [Implement file IO using pure Inko](https://github.com/inko-lang/inko/issues/633)
- [Implement socket IO using pure Inko](https://github.com/inko-lang/inko/issues/752)
- [Implement std.sys.Command in pure Inko](https://github.com/inko-lang/inko/issues/753)

## Warnings for unused imports

In [0.14.0](/news/inko-0-14-0-released/#warnings-for-unused-variables) we added
support for producing compile-time warnings for unused variables. In 0.17.0
we've extended this to also produce warnings for unused imported symbols. For
example, take this program:

```inko
import std.stdio (Stderr, Stdout)

class async Main {
  fn async main {
    Stdout.new.print('hello')
  }
}
```

Here `Stderr` is unused and so the compiler produces the following warning:

```
test.inko:1:19 warning(unused-symbol): the symbol 'Stderr' is unused
```

## Checking if a TTY is used

The standard library types `Stdio`, `Stdout` and `Stderr` now support a
`terminal?` method that returns `true` if the stream is connected to a
terminal/TTY. For example:

```inko
import std.stdio (Stdin, Stdout)

class async Main {
  fn async main {
    Stdout.new.print(Stdin.new.terminal?.to_string)
  }
}
```

This writes `true` to STDOUT when run in an interactive terminal, and `false`
otherwise (e.g. when running the program as part of a pipeline).

## Chaining iterators

Thanks to [Ryan Frame][rjframe], the standard library `Iter` type supports
chaining of two iterators together using [`Iter.chain`](https://docs.inko-lang.org/std/v0.17.0/module/std/iter/Iter/#method.chain):

```inko
import std.stdio (Stdout)

class async Main {
  fn async main {
    let a = [10, 20, 30]
    let b = [40, 50, 60]
    let out = Stdout.new

    a.into_iter.chain(b.into_iter).each(fn (val) { out.print(val.to_string) })
  }
}
```

This produces the following:

```
10
20
30
40
50
60
```

## Buffered writes

This release introduces the standard library type
[`std.io.BufferedWriter`](https://docs.inko-lang.org/std/v0.17.0/module/std/io/BufferedWriter/).
This type implements [`std.io.Write`](https://docs.inko-lang.org/std/v0.17.0/module/std/io/Write/)
and buffers writes, reducing the amount of underlying IO operations:

```inko
import std.io (BufferedWriter)
import std.stdio (Stdout)

class async Main {
  fn async main {
    BufferedWriter.new(Stdout.new).print('hello')
  }
}
```

## Parsing and generating CSV data

The newly added module
[`std.csv`](https://docs.inko-lang.org/std/v0.17.0/module/std/csv/) provides
types for parsing and generating CSV data, conforming to [RFC
4180](https://www.rfc-editor.org/rfc/rfc4180). For example, parsing a CSV stream
is done as follows:

```inko
import std.csv (Parser)
import std.fmt (fmt)
import std.io (Buffer)
import std.stdio (Stdout)

class async Main {
  fn async main {
    let parser = Parser.new(Buffer.new('foo,bar'))
    let rows = []

    parser.each(fn (result) { rows.push(result.get) })
    Stdout.new.print(fmt(rows))
  }
}
```

This produces the following output:

```
[["foo", "bar"]]
```

Generating CSV data is done as follows:

```inko
import std.csv (Generator)
import std.stdio (Stdout)

class async Main {
  fn async main {
    Generator.new(Stdout.new).write(['foo', 'bar'])
  }
}
```

This produces the following output:

```
foo,bar\r\n
```

## Building the compiler on Alpine now works (again)

A long time ago, Inko supported Alpine. Since the switch to compiling to machine
code using LLVM, Alpine wasn't supported due to the
[llvm-sys](https://gitlab.com/taricorp/llvm-sys.rs) crate (which we use for
interfacing with LLVM) not building on Alpine. This problem was fixed by [this
merge request](https://gitlab.com/taricorp/llvm-sys.rs/-/merge_requests/46).
This means that starting with Inko 0.17.0, Alpine is supported once more.

## Bug fixes

This release includes the following bug fixes:

- [Fix unreliable ordering when specializing types ](https://github.com/inko-lang/inko/commit/a77e53ba09f4e2ed13579b16940ff010477c0737)
- [Fix formatting of binding patterns](https://github.com/inko-lang/inko/commit/f94e4d1ecd81f8d53a8659e65f81763fd1397f23)
- [Escape ampersands in MIR Graphviz output](https://github.com/inko-lang/inko/commit/0bcb617187a1c663f8a30d67f6044183581821cc)
- [Fix building the compiler on Alpine/musl](https://github.com/inko-lang/inko/commit/e0feaaee9d5050056737bd473afe8fb2f7109df4)
- [Limit the number of threads for subprocess tests](https://github.com/inko-lang/inko/commit/3a17396f1a58f7f8986f9ccf51577fa94e040f89)
- [Refactor messages to support non-word arguments](https://github.com/inko-lang/inko/commit/33408cb07a55a771cc78e46e29fe052d79ab021d)
- [Fix capturing of C structures](https://github.com/inko-lang/inko/commit/125a4a8b6ecc056019ae0a62ad31e6c62db8e007)


## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

If you'd like to support the continued development of Inko, please consider
donating using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse) as
this allows us to continue working on Inko full-time.

[rjframe]: https://github.com/rjframe
