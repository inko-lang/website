---
{
  "title": "Inko 0.14.0 released",
  "date": "2024-02-05T12:00:00Z"
}
---

We're pleased to announce the release of Inko 0.14.0. This release contains a
variety of exciting changes, such as support for parallel and incremental
compilation, cross compilation, faster linking, and more!

## [Table of contents]{toc-ignore}

::: toc
:::

For the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.14.0/CHANGELOG.md#0140-2024-02-05).

A special thanks to the following people for contributing changes included in
this release:

- [Axel Pahl](https://github.com/apahl)

We'd also like to thank the following people for financially supporting the
development of Inko:

- [Amidamaru](https://github.com/thaodt)
- [Dusty Phillips](https://dusty.phillips.codes)
- [Evan Ovadia](https://github.com/Verdagon)
- [Kiril Mihaylov](https://github.com/KirilMihaylov)
- [SEKUN](https://sekun.dev)

We'd also like to thank the [NLnet foundation][nlnet] for sponsoring part of the
work that went into this release.

## Parallel compilation of object files

::: info
Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature.
:::

Inko uses LLVM for generating machine code, but LLVM is rather slow. To reduce
compile times, Inko now compiles LLVM modules (and thus object files) in
parallel. In case of Inko's own standard library test suite, the use of parallel
compilation reduces compile times by a factor of four on a computer with four
cores and eight threads.

The implementation is reasonably straightforward: the compiler spawns a number
of threads equal to the number of CPU cores (by default, this can be changed
using a command-line option). The work "queue" is an atomic counter that starts
at zero. Each thread races to increment the counter using an atomic swap.
Whenever a thread succeeds, it uses the resulting value to index an array of
modules to compile, then performs the necessary work. When threads reach the
maximum value (equal to the number of modules), they stop.

This setup means there's no need for any sort of locking or complex concurrent
data structures, as the only shared mutable state is an atomic counter. This in
turn means the setup scales well as the number of CPU cores goes up.

See commit
[9162406](https://github.com/inko-lang/inko/commit/91624062fa842362eafba3c8388922d89e9d713c)
for more details.

## Incremental compilation of object files

In addition to compiling machine code in parallel, we also perform incremental
compilation at the LLVM IR/object file level. This means we only recompile
object files if needed, greatly reducing compile times. When using a single
thread to compile Inko's standard library test suite, we found that incremental
compilation reduces compile times by a factor of 8 in the best case scenario.
When combining this with parallel compilation, we observed reductions of a
factor of 3, depending on the number of threads used.

Implementing this proved rather tricky, as we had to make sure that when
compiling the same code, the compiler performs the same work in the same order
every time. For example, symbol names used to include the numerical IDs of
methods, but these IDs change based on the order in which they're processed. To
solve that, symbol names now use a different name mangling scheme to ensure
they're unique, without depending on the order in which code is processed.

In it's current implementation there are certain scenarios in which caches are
flushed even though this isn't strictly necessary. In general such cases are
rare, and it's something we hope to improve in the future when the need for this
arises.

See commit
[137304d](https://github.com/inko-lang/inko/commit/137304d1cdf6db7d04350fe5675d540fc5543618)
for more details.

## Faster linking of object files using Mold

If you're using Linux and have [Mold](https://github.com/rui314/mold) installed,
Inko's compiler automatically uses it for linking object files, similar to how
it automatically uses [LLD](https://lld.llvm.org/) if it's available. If both
Mold and LLD are installed, the compiler favours Mold over LLD.

See commit
[76cf292](https://github.com/inko-lang/inko/commit/76cf292cabdfa3a3b23e7465968b55c05e8debe5)
for more details.

## Support for cross compilation

::: info
Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature.
:::

Cross compilation allows you to compile your programs from one target (e.g.
AMD64 Linux) to a different target (e.g. ARM64 macOS), without the need for
extra hardware. Starting with version 0.14.0, Inko officially supports cross
compilation to different targets.

To make this as easy as possible, Inko tries to automatically detect what
toolchain to use for cross compilation. For example, if
[Zig](https://ziglang.org/) is installed the compiler favours it over GCC and
clang, as cross compilation using Zig is much easier compared to the
alternatives.

Cross compilation requires a version of the Inko runtime suitable for the
compilation target. To remove the need for manually compiling the runtime for
each target, we provide pre-built versions of the runtime which are installed
using the `inko runtime add` command. Take the following program for example:

```inko
import std.stdio.STDOUT

class async Main {
  fn async main {
    STDOUT.new.print('hello')
  }
}
```

To cross compile this to AMD64 macOS using Zig, all we need to do is:

1. Make sure Zig is installed
1. Run `inko runtime add amd64-mac-native`
1. Run `inko build --target amd64-mac-native test.inko` to build the program

Of course without Zig cross compilation is still supported, but the process is a
bit more difficult depending on what target you're compiling to. For more
details, refer to the [cross compilation
documentation](https://docs.inko-lang.org/manual/v0.14.0/guides/cross
compilation/)

Inko supports cross compiling to AMD64 and ARM64 macOS and Linux, and AMD64
FreeBSD. ARM64 FreeBSD is supported at the compiler level, but we don't provide
pre-built runtimes for FreeBSD as we use [rustup](https://rustup.rs/) as part
of building the runtimes, and rustup doesn't provide any pre-built targets for
this target.

See commit
[03ef71f](https://github.com/inko-lang/inko/commit/03ef71f59c6178d6438e5546d8e1139bc4a4a16b)
for more details.

## Support for compiling with musl

As part of the cross compilation work, we've also added support for compiling
Inko programs using [musl](https://www.musl-libc.org/). This allows you to build
Linux executables that don't depend on glibc and as such are much more portable.
To compile using musl, use the `amd64-linux-musl` or `arm64-linux-musl` target:

```
inko runtime add amd64-linux-musl
inko build --target amd64-linux-musl test.inko
```

When targeting musl from a GNU host, musl is statically linked. If the host is
instead a musl host (e.g. Alpine Linux), the compiler _dynamically_ links musl
by default to match the expected behaviour on such hosts. In such cases you can
force static linking by using `inko build --static`.

## Additions to the standard library

This releases includes a variety of additions to the standard library, such as
more methods for the `Path` type
([`Path.extension`](https://github.com/inko-lang/inko/commit/f4d3c5aa10e7cb135a31cf777ad79b1449d1ec0d),
[`Path.with_extension`](https://github.com/inko-lang/inko/commit/4ee577a09c8e21446b7ccf9ba05fec2772c1d46a),
[`Path.list_all`](https://github.com/inko-lang/inko/commit/46b5fc284006cc7bc41f08eb6f0ee43f21635fb7),
and more), support for [replacing
strings](https://github.com/inko-lang/inko/commit/e2879560e387631a14bf13f73aaf1cd7cd761e1a),
and methods for [querying JSON
values](https://github.com/inko-lang/inko/commit/7f5bcac69345f95d3f2471f736d841c6438c0daf).
This new querying API allows you to query JSON documents as follows:

```inko
import std.json.Json
import std.stdio.STDOUT

class async Main {
  fn async main {
    let json = Json
      .parse('{ "name": "Donald Duck" , "address": { "city": "Duckburg" } }')
      .unwrap

    let city = json.query.key('address').key('city').as_string.unwrap
    let stdout = STDOUT.new

    stdout.print(city)
  }
}
```

## Warnings for unused variables

Inko's compiler now produces warnings for unused local variables. This seemingly
minor feature can prove useful in finding redundant code, as seen in [this
commit](https://github.com/inko-lang/website/commit/d4098170b71661c69b5c1e561c4a931ef6e1192a)
removing various bits of unused code.

See commit
[ac24bcc](https://github.com/inko-lang/inko/commit/ac24bcc38f16df9f43fdbc0ae9e29394072d939a)
for more details.

## A new Inko manual

[Inko's manual](https://docs.inko-lang.org/manual/v0.14.0/) has received a
significant overhaul. Instead of using [mkdocs](https://www.mkdocs.org/), it's
now built using Inko itself using the
[inko-wobsite](https://github.com/yorickpeterse/inko-wobsite) static site
generator, and it uses a new style more in line with the main website. As part
of this we also rewrote and reorganized large parts of the manual.

As part of these changes the ability to search the manual has been removed. We
may reintroduce this at some point in the future, when we figure out a solution
that provides good and relevant search results (which the old search function
didn't always do).

You can find the latest version of the new manual
[here](https://docs.inko-lang.org/manual/latest/), and the version for the
`main` branch is found [here](https://docs.inko-lang.org/manual/main/).

## Rust 1.70 is now required

The minimum required version of Rust is increased from 1.68.0 to 1.70.0,
allowing us to take advantage of some newer Rust features.

## A lot of bug fixes

This release includes many fixes, such as fixes for
[OR patterns](https://github.com/inko-lang/inko/commit/8b7f0d2eea85bbece2338a0aafa8c7f266d032aa),
[guard patterns](https://github.com/inko-lang/inko/commit/895826b25b757b32e38af40e3034a0d3ac1d2f49),
[uniqueness checking for Channels](https://github.com/inko-lang/inko/commit/4a4edb1a440543c7fa04398c1ac7bfc1f9fa7c73),
[compile-time memory usage](https://github.com/inko-lang/inko/commit/3c3c73adcf73eaf77a3eabf82bb07aa394719ef1),
and much more.

## [Plans for 0.15.0]{toc-ignore}

For the next version of Inko, we'll be working on [generating source code
documentation](https://github.com/inko-lang/inko/issues/333), [automatic code
formatting](https://github.com/inko-lang/inko/issues/334), various improvements
to the type system (e.g. making working with closures easier), and more.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/). If you'd like to support
the continued development of Inko, please consider donating using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).

[nlnet]: https://nlnet.nl/
[nlnet-announcement]: /news/inko-0-12-0-released/#inko-receives-funding-from-nlnet
