---
{
  "title": "Inko 0.18.1 is released",
  "date": "2025-02-12"
}
---

We're pleased to announce the release of Inko 0.18.1. This release includes
support for stack allocated types, parsing and formatting of dates and times,
the enabling of LLVM optimizations, and more.

## [Table of contents]{toc-ignore}

::: toc
:::

This release includes many changes not listed in this announcement. For the full
list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.18.1/CHANGELOG.md#0180-2025-02-11).

A special thanks to the following people for contributing changes included in
this release:

- [evomassiny](https://github.com/evomassiny)

## The class keyword is replaced with a type keyword

Types used to be defined using the `class` keyword. Starting with 0.18.1, the
`class` keyword is deprecated in favor of the `type` keyword. This means that
instead of this:

```inko
class async Main {
  ...
}
```

You now write this:

```inko
type async Main {
  ...
}
```

To make the transition process easier, the compiler supports both the `class`
and `type` keywords and the `inko fmt` command automatically replaces the
`class` keyword with the `type` keyword. This means that to upgrade your project
to use this new syntax, all you need to do is run `inko fmt` and commit your
changes.

Support for the `class` keyword will be removed in 0.19.0, so make sure to
update your projects before upgrading to 0.19.0 when it's released.

## Support for stack allocated types

This version introduces support for types that are allocated on the stack/inline
to their owner. Such types are defined using the `inline` keyword when defining
a type. For example:

```inko
type inline User {
  let @name: String
  let @age: Int
}

User(name: 'Alice', age: 42) # This value is on the stack, not on the heap
```

Stack allocated types are useful for short-lived types or simple wrapper types,
and avoid the need for a heap allocation and pointer indirection. LLVM is also
better at optimizing stack allocated types compared to heap allocated types.

In addition, one can define a inline type that's trivial to copy using the
`copy` keyword:

```inko
type copy Time {
  let @hour: Int
  let @minute: Int
  let @second: Int
}
```

Types defined using the `copy` keyword can only contain other `copy` types
(= `Int`, `Float`, `Bool`, `Nil`, and custom `copy` types). Copy types are also
immutable and thus don't allow any `fn mut` methods, unlike `inline` types.

As part of this change, a variety of types provided by the standard library are
turned into `inline` types such as [`std.option.Option`](https://docs.inko-lang.org/std/v0.18.1/module/std/option/Option/)
and [`std.result.Result`](https://docs.inko-lang.org/std/v0.18.1/module/std/result/Result/).

To ensure memory safety, borrowing of inline types works a little different
compared to heap types. When borrowing a heap type, a single borrow counter is
incremented and decremented when the borrow is no longer needed. When borrowing
an inline type, the inline/stack data is _copied_ (which itself is cheap) and
the borrow counter for _each_ heap type stored in the inline type is
incremented. Thus, if an inline type stores 10 heap types (e.g. 10 arrays),
borrowing that inline type incurs 10 increments and 10 corresponding decrements.

`copy` types don't have this cost because they can't store heap allocated
values. This makes copying them trivial, but also limits their use.

In addition, fields of `inline` types can't be assigned new values. Because
borrowing an inline value creates a copy, assigning a field a new value would
mean the assignment is only visible using that exact copy. Because of the
surprising behavior this can lead to, we don't allow fields assignments for
inline types, though we are [investigating potential
solutions](https://github.com/inko-lang/inko/issues/810) to this problem.

For more information, refer to the [documentation of inline
types](https://docs.inko-lang.org/manual/v0.18.1/getting-started/types/#inline-types).

## Fields no longer allow assignments by default

Similar to local variables, fields can no longer be assigned new values _unless_
they are explicitly defined as mutable fields:

```inko
type User {
  let @name: String
  let mut @age: Int
}

type async Main {
  fn async main {
    let user = User(name: 'Alice', age: 42)

    user.name = 'Bob' # This isn't allowed because `name` isn't `mut`

    user.age = 43 # This _is_ allowed because the field is defined using `let mut`
  }
}
```

This change means it's now possible to expose public fields that _can't_ be
assigned new values, something that wasn't possible before.

## LLVM optimizations are now applied

Before 0.18.1, running `inko build` resulted in no LLVM optimizations passes
running as we had yet to figure out which ones are worth enabling. As part of
[this issue](https://github.com/inko-lang/inko/issues/595) we looked into this
and ended up changing things as follows:

- `inko build --opt=none` doesn't apply any optimizations, meaning it's
  similar to `clang -O0`
- `inko build` / `inko build --opt=balanced` applies optimizations
  similar to `clang -O2`, with some small changes to better suit our needs
- `inko build --opt=aggressive` applies optimizations similar to `clang
  -O3`. Most of the time this won't make a difference runtime performance wise,
  but we may extend the list of optimizations in the future

When running tests using `inko test`, optimizations are disabled.

The use of an explicit list of optimizations means you _may_ run into issues
when using LLVM 19 or newer as it appears LLVM 19 made some changes related to
certain optimization passes. If this is the case, you can work around this using
`inko build --opt=none` for the time being or build using an older version of
LLVM. For more details, refer to [this
issue](https://github.com/inko-lang/inko/issues/816).

## Support for resolving DNS names using std.net.dns

This release includes a new module for performing DNS name resolution:
[`std.net.dns`](https://docs.inko-lang.org/std/v0.18.1/module/std/net/dns/).
For example, we can resolve `one.one.one.one` into a list of IP addresses as
follows:

```inko
import std.fmt (fmt)
import std.net.dns (Resolver)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let dns = Resolver.new
    let out = Stdout.new

    out.print(fmt(dns.resolve('one.one.one.one')))
  }
}
```

This produces the following output:

```
Ok([1.0.0.1, 1.1.1.1, 2606:4700:4700::1001, 2606:4700:4700::1111])
```

The `Resolver` type uses different backends for different platforms. The choice
of backend is determined at _runtime_, not at compile-time. For macOS and
FreeBSD, the `getaddrinfo()` function is used. For Linux we try to detect the
presence of
[systemd-resolved](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html)
and if present will use its [varlink](https://varlink.org/) API. This API allows
resolving of DNS names using Inko's non-blocking socket API, which can greatly
improve performance compared to `getaddrinfo()`. If systemd-resolved isn't
available, the Linux backend falls back to using `getaddrinfo()`.

When using the systemd-resolved backend it's also possible to specify a timeout
for DNS lookups using
[`std.net.dns.Resolver.timeout_after=`](https://docs.inko-lang.org/std/v0.18.1/module/std/net/dns/Resolver/#method.timeout_after=).
This timeout is ignored by the `getaddrinfo()` backend as `getaddrinfo()`
doesn't support custom timeouts.

The `getaddrinfo()` backend is implemented using
[`std.io.start_blocking`](https://docs.inko-lang.org/std/v0.18.1/module/std/io/start_blocking/)
and
[`std.io.stop_blocking`](https://docs.inko-lang.org/std/v0.18.1/module/std/io/stop_blocking/),
ensuring such blocking calls don't exhaust the available (primary) OS threads.
As the [number of backup
threads](https://docs.inko-lang.org/manual/v0.18.1/references/tuning/#inko_backup_threads)
used for blocking system calls is fixed, it's still possible to exhaust those
threads. For this reason we _highly_ recommend to use systemd-resolved when
deploying to Linux as the systemd-resolved backend doesn't suffer from this
problem.

## Support for RFC 8305: Happy Eyeballs

The type [`std.net.socket.TcpClient`](https://docs.inko-lang.org/std/v0.18.1/module/std/net/socket/TcpClient/)
supports [RFC 8305](https://datatracker.ietf.org/doc/html/rfc8305) when using
the following methods:

- [`std.net.socket.TcpClient.new`](https://docs.inko-lang.org/std/v0.18.1/module/std/net/socket/TcpClient/#method.new)
- [`std.net.socket.TcpClient.with_timeout`](https://docs.inko-lang.org/std/v0.18.1/module/std/net/socket/TcpClient/#method.with_timeout)

Instead of expecting a single IP address and port, these methods now expect an
array of IP addresses and a port and will use the RFC 8305 algorithm to
efficiently (and as fast as possible) establish a connection. Combined with the
new `std.net.dns.Resolver` type, connecting to a hostname is done as follows:

```inko
import std.net.dns (Resolver)
import std.net.socket (TcpClient)

type async Main {
  fn async main {
    let dns = Resolver.new
    let ips = dns.resolve('one.one.one.one').or_panic('DNS lookup failed')

    TcpClient.new(ips, port: 443).or_panic('failed to connect')
  }
}
```

Support for RFC 8305 does incur a small cost due to the extra bookkeeping that's
necessary. If necessary you can avoid this cost by providing an array containing
only a single IP address:

```inko
import std.net.dns (Resolver)
import std.net.socket (TcpClient)

type async Main {
  fn async main {
    let dns = Resolver.new
    let ips = dns.resolve('one.one.one.one').or_panic('DNS lookup failed')

    TcpClient.new([ips.get(0)], port: 443).or_panic('failed to connect')
  }
}
```

As part of these changes, `TcpClient.new` is changed to no longer wait
indefinitely for a connection to establish and instead enforces a timeout of 5
seconds. If you need a custom timeout you can use `TcpClient.with_timeout`
instead.

## Support for parsing and formatting DateTime values

The type
[`std.time.DateTime`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/DateTime/)
now supports parsing and formatting using the following methods:

- [`DateTime.parse`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/DateTime/#method.parse)
- [`DateTime.format`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/DateTime/#method.format)

Both parsing and formatting is locale-aware and the standard library provides
locale information for Dutch, English, and Japanese. For example:

```inko
import std.locale.en
import std.locale.ja
import std.stdio (Stdout)
import std.time (DateTime)

type async Main {
  fn async main {
    let out = Stdout.new
    let en = en.Locale.new
    let ja = ja.Locale.new
    let dt = DateTime
      .parse('2025-02-12 02:13', format: '%Y-%m-%d %H:%M', locale: en)
      .or_panic('failed to parse the input')

    out.print(dt.format('%B %d, %Y', locale: ja))
    out.print(dt.format('%B %d, %Y', locale: en))
  }
}
```

This produces the following output:

```
2月 12, 2025
February 12, 2025
```

In addition, `DateTime` is now split into the following types:

- [`std.time.Time`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/Time/):
  a type that represents a pair of hours, minutes, seconds and
  nanoseconds.
- [`std.time.Date`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/Date/):
  a type that represents the year, month and day in the Gregorian calendar
- [`std.time.DateTime`](https://docs.inko-lang.org/std/v0.18.1/module/std/time/DateTime/):
  a type that combines the `Date` and `Time` types along with the UTC offset (in
  seconds)

## Parsing JSON from Read types

The types [`std.json.Parser`](https://docs.inko-lang.org/std/v0.18.1/module/std/json/Parser/)
(typically used through the [`std.json.Json.parse`](https://docs.inko-lang.org/std/v0.18.1/module/std/json/Json/#method.parse)
method) and [`std.json.PullParser`](https://docs.inko-lang.org/std/v0.18.1/module/std/json/PullParser/)
now expect a type that implements [`std.io.Read`](https://docs.inko-lang.org/std/v0.18.1/module/std/io/Read/)
as their input, instead of a `String` or `ByteArray`. This makes it possible to
parse e.g. a file without first having to read the entire file into memory.

If you want to parse an existing `String` or `ByteArray`, you have to wrap it in
a [`std.io.Buffer`](https://docs.inko-lang.org/std/v0.18.1/module/std/io/Buffer/)
like so:

```inko
import std.io (Buffer)
import std.json (Json)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let doc = Json.parse(Buffer.new('{ "name": "Alice" }')).or_panic(
      'the JSON is invalid',
    )

    let name = doc.query.key('name').as_string.or_panic(
      'the "name" key is required and must be a string',
    )
    let out = Stdout.new

    out.print(name) # => 'Alice'
  }
}
```

In addition, the type
[`std.json.ObjectParser`](https://docs.inko-lang.org/std/v0.18.1/module/std/json/ObjectParser/)
exposes a different API compared to previous version. For 0.19.0 we'll likely
make further changes to the pull parsing API as we're [not
satisfied](https://github.com/inko-lang/inko/issues/719) with the current setup.

## Self types are back

`Self` is a type that acts as a sort of placeholder: when used inside a trait
definition, it refers to the type that implements the trait. When used in a type
definition, it refers to the type itself. Inko used to support `Self` types, but
support was removed as part of the [0.11.0 release](/news/inko-0-11-0-released)
due to the complex and buggy implementation.

In this release we reintroduce support for `Self` types, but this time using an
implementation that's easier to maintain and less likely to introduce bugs. As
part of this release, the following types have been adjusted to use `Self`
instead of using generic type parameters:

- [`std.cmp.Equal`](https://docs.inko-lang.org/std/v0.18.1/module/std/cmp/Equal/)
- [`std.cmp.Compare`](https://docs.inko-lang.org/std/v0.18.1/module/std/cmp/Compare/)
- [`std.clone.Clone`](https://docs.inko-lang.org/std/v0.18.1/module/std/clone/Clone/)

This means that instead of implementing these types like this:

```inko
import std.cmp (Compare, Equal)
import std.clone (Clone)

type Type {}

impl Compare[Type] for Type {
  ...
}

impl Equal[Type] for Type {
  ...
}

impl Clone[Type] for Type {
  ...
}
```

You implement them like this instead:


```inko
import std.clone (Clone)
import std.cmp (Compare, Equal)

type Type {}

impl Compare for Type {
  ...
}

impl Equal for Type {
  ...
}

impl Clone for Type {
  ...
}
```

In addition, the type of `self` in default trait methods is now `Self` and you
can no longer cast it to a trait value (i.e. `self as ToString`), fixing [this
soundness hole](https://github.com/inko-lang/inko/issues/787).

## Fixes for ensuring types are sendable

For a value to be safe to be moved between processes, it must be "sendable". A
value is sendable when it's guaranteed the sender retains no references to it
and the value retains no references to any data owned by the sender. It's a bit
like [a carrot in a box](https://www.youtube.com/watch?v=0UGuPvrsG3E): you can
move the box around, but you can't look inside the box _unless_ you're willing
to give up the ability to move it between processes afterwards.

In 0.18.1 various compiler bugs related to ensuring a value is sendable are
fixed. This in turn revealed that in certain cases the checks were in fact _too_
strict, resulting in otherwise valid code being rejected, something we found out
_after_ starting work on releasing 0.18.0, hence this announcement is about
0.18.1 and not 0.18.0.

Most notably, past versions allowed you to pass borrows of `uni T` values to
`ref` arguments:

```inko
type Thing {}

fn example(values: mut Array[ref Thing], thing: ref Thing) {
  values.push(thing)
}

type async Main {
  fn async main {
    let thing = recover Thing()
    let vals = []

    example(vals, thing)
  }
}
```

Code like this is unsound as it results in an alias to the `uni Thing` value
stored in the `thing` variable, and thus this is no longer allowed.

## Inlining of constants

The compiler is now able to inline constants of type `Int`, `Float` and `Bool`.
In addition, such constants are removed from the executable as there's no point
in keeping them around. This results in better code generation and smaller
executables. Constants of type `Array` are _not_ inlined as doing so would
require allocating the `Array` at runtime, which would likely have a negative
impact on performance.

## Parallel method-local optimizations

The compiler performs various (simple) optimizations on individual
methods, and these optimizations don't rely on any shared mutable state.
Starting with 0.18.1 these optimizations are performed in parallel to reduce
compile times.

The exact impact depends on the allocator in use. When using the glibc allocator
there's almost no difference between performing these optimizations in parallel
versus performing them sequentially, but when using
[jemalloc](https://jemalloc.net/) the time spent performing these optimizations
is reduced by a factor of up to 2.5 (compared to performing the work
sequentially using jemalloc).

## Enums use less memory

Each enum has a tag that indicates which constructor is used to create it
(also known as a "variant"). The type of this tag used to be a 64 bits integer
and would thus require 8 bytes of memory. Starting with 0.18.1, we now use a 16
bits integer such that the tag only needs 2 bytes of space. We are also looking
into changing this to use [a single byte when
possible](https://github.com/inko-lang/inko/issues/807) in the future, further
reducing memory usage of enums.

## Plans for 0.19.0

For 0.19.0 we plan to work on at least the following:

- Add support for performing [HTTP(s)
  requests](https://github.com/inko-lang/inko/issues/734) (starting with
  HTTP 1.1 and possibly also HTTP 2),
- [Futher improve the JSON pull parsing API](https://github.com/inko-lang/inko/issues/719)
- [Implement some form of escape
  analysis](https://github.com/inko-lang/inko/issues/776) to reduce the amount
  of heap allocations
- [Introduce syntax for `for`
  loops](https://github.com/inko-lang/inko/issues/817) to make iterating over
  data easier (in particular when using nested loops)
- [Make it easier to provide multiple
  executables](https://github.com/inko-lang/inko/issues/625) in a single project
- [Add support for LLVM 19](https://github.com/inko-lang/inko/issues/816)

The exact list is found [here](https://github.com/inko-lang/inko/milestone/31)
but is more of a guideline rather than a list of hard requirements.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb) or star the [project on
GitHub](https://github.com/inko-lang/inko). You can also subscribe to the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

Development of Inko is self-funded, but this isn't sustainable. If you'd like to
support the development of Inko and can spare $5/month, _please_ become a
[GitHub sponsor](https://github.com/sponsors/YorickPeterse) as this allows us to
continue working on Inko full-time.
