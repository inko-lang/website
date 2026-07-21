---
{
  "title": "Inko 0.21.1: Argon2, BLAKE2b, performance improvements and more",
  "date": "2026-07-21"
}
---

We're pleased to announce the release of Inko 0.21.1. This release includes
support for Argon2, BLAKE2b, various bug fixes and performance improvements.

::: note
During the release we encountered a bug that meant we had to start the release
process over again, hence the jump from 0.20.0 to 0.21.1.
:::

If you're new to Inko: Inko is a programming language for building concurrent
software, but without the usual headaches such as data race conditions and
non-deterministic garbage collectors. Inko features deterministic automatic
memory management, compiles to machine code using LLVM, supports different
platforms (Linux, macOS and FreeBSD), and is easy to get started with. For more
information, refer to the [homepage](/) or the
[manual](https://docs.inko-lang.org/manual/v0.21.1/).

## [Table of contents]{toc-ignore}

::: toc
:::

This release includes changes not included in this announcement. For the full
list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.21.1/CHANGELOG.md#0211-2026-07-20).

A special thanks to the following people for contributing changes included in
this release:

- [Anton](https://github.com/shindakioku)
- [Joe Santos](https://github.com/iamajoe)
- [Tomoki Aonuma](https://github.com/uasi)

## Argon2

[Argon2](https://en.wikipedia.org/wiki/Argon2) is a key derivation function
commonly used for hashing passwords. This releases introduces an implementation
of [Argon2id](https://docs.inko-lang.org/std/v0.21.1/module/std/crypto/argon2/Argon2/)
as part of the standard library:

```inko
import std.crypto.argon2 (Argon2)
import std.rand (Random)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let rng = Random.new
    let salt = ByteArray.new

    rng.bytes(into: salt, size: 16)

    let hash = Argon2.new.hash(password: 'hunter2', salt: salt).to_string
    let out = Stdout.new

    out.print(hash) # => '$argon2id$v=19$m=16384,t=3,p=1$...'
  }
}
```

## BLAKE2b

[BLAKE2](https://en.wikipedia.org/wiki/BLAKE_\(hash_function\)#BLAKE2) is a
cryptographic hash function, similar to SHA1 and others. This release introduces
an implementation of [BLAKE2b](https://docs.inko-lang.org/std/v0.21.1/module/std/crypto/blake2/Blake2b/)
as part of the standard library:

```inko
import std.crypto.blake2 (Blake2b)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let out = Stdout.new

    out.print(Blake2b.hash('abc').to_string)
  }
}
```

## Binary integer literals

This release introduces support for binary integer literals, something we've
been meaning to add for a while now but never got around to implementing:

```inko
0b1101  # => 13
0b11_01 # => 13
```

## Resolving of compiler directories at runtime

The compiler needs to know where the standard library and the runtime library
(`libinko.a`) is located. Starting with 0.21.1 these directories are resolved at
runtime relative to the compiler's location, instead of the paths being
specified at compile-time using the `INKO_STD` and `INKO_RT` environment
variables. This makes it easier to support relocatable package managers such as
[Pixi](https://pixi.prefix.dev/latest/). The mentioned environment variables are
still supported and honored when specified, but they are no longer _required_.

## Parsing and formatting of integers

The methods `Int.parse` and `Int.format` no longer rely on the `std.int.Format`
type to specify the input/output format, instead they use a `base:` argument
that specifies the integer base as an `Int`, so instead of this:

```inko
import std.int (Format)

Int.parse('10', Format.Decimal)
10.format(Format.Decimal)
```

You now write this:

```inko
Int.parse('10', base: 10)
10.format(base: 10)
```

This removes the need for importing an extra type (of which the name is likely
to conflict with other types), while also supporting different number bases
should you have a need for this.

For more details, refer to [this
issue](https://github.com/inko-lang/inko/issues/910).

## Reduced memory usage for Future and Promise

The types
[`Future`](https://docs.inko-lang.org/std/v0.21.1/module/std/sync/Future/) and
[`Promise`](https://docs.inko-lang.org/std/v0.21.1/module/std/sync/Promise/) are
primitives used for communicating the result of a message back to another
process (e.g. the sender). The implementation of these types is now optimized
such that only a single heap allocation is required instead of three
(one for the `Future`, one for the `Promise` and one for their shared state).

In addition, `Future.get` no longer deadlocks when called during or after
dropping the corresponding `Promise` and will instead trigger a panic in such
cases.

## Removal of the Stream type

The type `std.iter.Stream` was used to make implementing iterators easier using
closures. Unfortunately, this would result in inefficient iterator code as the
compiler is not able to inline and optimize the code in many instances.

This release removes the type entirely in favor of writing iterators using
dedicated types. While this approach is more verbose, it allows the compiler to
inline and optimize the code more effectively.

## Changes to `Map.try_set`

The method
[`Map.try_set`](https://docs.inko-lang.org/std/v0.21.1/module/std/map/Map/#method.try_set)
now returns a mutable borrow of the value if the value is inserted. Thanks to
Tomoki Aonuma for [contributing this
change](https://github.com/inko-lang/inko/commit/2b6bd554e6793fc7f0271f382269bf4acdc5480b)!

## Directory locks when compiling code

The compiler now uses a set of lock files to ensure that concurrent access to
the same directories (e.g. the `dep/` directory of a project) is synchronized,
preventing concurrent instances of the compiler from messing up each other's
state.

For more details, refer to [this
commit](https://github.com/inko-lang/inko/commit/83e707045819e70b8c3d9535cf1c6ab542f98221)
and [this commit](https://github.com/inko-lang/inko/commit/e1094d23aa533530dd57d3fc6048a645f525eaf4).

## More consistent results for string splitting

The behavior of
[`String.split`](https://docs.inko-lang.org/std/v0.21.1/module/std/string/String/#method.split)/[`Slice.split`](https://docs.inko-lang.org/std/v0.21.1/module/std/bytes/Slice/#method.split)
is changed as part of this release to make it more consistent with other
programming languages:

1. A slice is generated for each separator, instead of skipping the last empty
   slice
1. An empty input produces a single empty slice instead of producing nothing

For more details, refer to [this commit](https://github.com/inko-lang/inko/commit/e703d6bc70db03d792eb5b94563bb42529adc253).

## Removal of redundant String reference counts

This release includes [a performance
optimization](https://github.com/inko-lang/inko/commit/d240af853004a1e71d785fbfc65b632807915048)
that is able to remove a significant amount of reference count operations for
the [`String`](https://docs.inko-lang.org/std/v0.21.1/module/std/string/String/)
type. The reduction ranges from 30% to 56%, based on measuring the impact on the
following projects:

- [yorickpeterse/openflow](https://github.com/yorickpeterse/openflow/): 30%
- [yorickpeterse/shost](https://github.com/yorickpeterse/shost/): 40%
- [KieranP/Game-Of-Life-Implementations](https://github.com/KieranP/Game-Of-Life-Implementations/): 56%

## SipHash is replaced with aHash

The standard library hash map type
[`Map`](https://docs.inko-lang.org/std/v0.21.1/module/std/iter/Map/) no longer
uses SipHash13 as its hashing algorithm and instead now uses the fallback
implementation (i.e. non-hardware accelerated) of
[aHash](https://github.com/tkaitchuck/aHash/). This hash algorithm has the same
DOS-resistance properties as SipHash13 while performing much better: 2-3 times
faster for integer keys while up to 20 times faster for string/bytes keys.

For more details, refer to [this
commit](https://github.com/inko-lang/inko/commit/f45d24a87a43c28e58a778c860225a234c947243)
and [this issue](https://github.com/inko-lang/inko/issues/828).

## An official Zed extension

Users of the [Zed editor](https://zed.dev/) can now use our [official
extension](https://zed.dev/extensions/inko). Thanks to Tomoki Aonuma for making
this possible!

## Allow use of unmoved fields when a field is moved conditionally

When a field is moved conditionally, the compiler would not only mark this field
as potentially moved but also (incorrectly) disallow use of any other unmoved
fields. For example, this code would be (incorrectly) rejected by the compiler:

```inko
import std.drop (drop)

type Inner {}

type Foo {}

type inline Outer {
  let @inner: Inner
  let @foo: Foo

  fn move submit {
    if true { drop(@inner) }

    drop(@foo)
  }
}

type async Main {
  fn async main {
    Outer(inner: Inner(), foo: Foo()).submit
  }
}
```

Thanks to [Anton](https://github.com/shindakioku) this bug is fixed and the
above code compiles as expected.

## Sendability is enforced for closures

A compiler bug meant that when calling closures typed as unique values (e.g.
`uni fn (Foo)`), the compiler didn't enforce that the arguments and the return
value are sendable types, allowing for unsound code. This releases fixes this so
the rules are the same as when calling methods on non-closure values.

For more details, refer to [this
commit](https://github.com/inko-lang/inko/commit/0980dc0cfdf0785d1884d8db5bba37ddc1ee0108).

## Unified IO error constructors

The [`Error`](https://docs.inko-lang.org/std/v0.21.1/module/std/io/Error/) is
produced in response to low-level IO errors, such as an attempt to read a
non-existing file. This releases merges the constructors `ConnectionReset`,
`BrokenPipe` and `ConnectionAborted` into a single [`Closed`
constructor](https://docs.inko-lang.org/std/v0.21.1/module/std/io/Error/#constructor.Closed),
making it easier to handle IO streams that are closed.

Refer to [this
commit](https://github.com/inko-lang/inko/commit/16f54228f47936344db2127c906037ba0d533162)
and [this issue](https://github.com/inko-lang/inko/issues/889) for more details.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb) or star the [project on
GitHub](https://github.com/inko-lang/inko). You can also subscribe to the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

Development of Inko is self-funded, but this isn't sustainable. If you'd like to
support the development of Inko and can spare $5/month, _please_ become a
[GitHub sponsor](https://github.com/sponsors/YorickPeterse) as this allows us to
continue working on Inko full-time.
