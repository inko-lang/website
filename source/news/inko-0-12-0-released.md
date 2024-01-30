---
{
  "title": "Inko 0.12.0 released",
  "date": "2023-06-05 18:45:03 UTC"
}
---

We're pleased to announce the release of Inko 0.12.0. This release contains
various bug fixes, and several new features.

## [Table of contents]{toc-ignore}

::: toc
:::

For a full list of all changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/main/CHANGELOG.md#0120-2023-06-05)
for this release.

## Inko receives funding from NLnet

[NLnet](https://nlnet.nl/) is a Dutch foundation that financially supports
organizations and people that contribute to an open information society. We
applied for a grant earlier this year. The application was a bit of a moonshot,
as we weren't entirely sure Inko would fall in the scope of NLnet. Upon seeing
that the [Oil shell](http://www.oilshell.org/) also [receives a
grant](https://nlnet.nl/project/OilShell/) from NLnet, we decided to give it a
try anyway. Two weeks ago we received confirmation that Inko's proposal has been
accepted, and a description of the project is found [on the NLnet
website](https://nlnet.nl/project/Inko/).

The funding we requested is a modest €8000 spread over a 12 month period,
resulting in €666 per month. While that number may seem a little suspicious,
it's just a coincidence: originally we had planned for a six month period, which
comes down to about €1200/month plus a little extra for taxes. Later we changed
that to a 12 month period as we felt six months likely isn't enough, and because
the donations turned out to be tax free, and it so happens that `8000 / 12 =
666.6`.

The exact details and planning are still being finalised, but at the least we're
planning to work on the following issues (not necessarily in this order):

- [Type-safe C FFI](https://github.com/inko-lang/inko/issues/290)
- [Add support for cross compilation](https://github.com/inko-lang/inko/issues/524)
- [Cache and reuse object files and/or LLVM bitcode when compiling to LLVM](https://github.com/inko-lang/inko/issues/520)
- [Specialise generic functions and types over kinds/shapes](https://github.com/inko-lang/inko/issues/525)
- [Consider implementing ByteArray and Array in Inko with a set of primitive instructions](https://github.com/inko-lang/inko/issues/349)
- [Support for TLS sockets](https://github.com/inko-lang/inko/issues/329)
- [Add cryptography ciphers/algorithms](https://github.com/inko-lang/inko/issues/499)

## Inko on Fedora copr

We now provide an official [Fedora copr
repository](https://copr.fedorainfracloud.org/coprs/yorickpeterse/inko/), making
it easier to install Inko on Fedora. Using this repository, you can install Inko
as follows:

```
sudo dnf install dnf-plugins-core
sudo dnf copr enable yorickpeterse/inko
sudo dnf install inko
```

## Various fixes related to dropping values

This release includes various fixes for values either not being dropped, or
being dropped twice. Specifically, the following issues are solved:

- [Pattern matching in certain cases appears to result in a reference counting underflow](https://github.com/inko-lang/inko/issues/519)
- [Assigning heap allocated integers to fields leaks memory](https://github.com/inko-lang/inko/issues/536)
- [Pattern matching against an owned tuple can result in dangling reference panics](https://github.com/inko-lang/inko/issues/563)
- [cmp.max segfaults when given two heap allocated floats](https://github.com/inko-lang/inko/issues/560)

## Processes suspended with timeouts use less memory

Commit
[e611ace](https://github.com/inko-lang/inko/commit/e611acecfb99cd5929ba647031df31e5dd5db4e5)
improves the memory layout of internal data structures used to keep track of how
long a process needs to be suspended for. While the reduction is only 8 bytes
(from 16 to 8 bytes) per timeout, this can add up when _a lot_ of processes are
suspended.

## Unreachable code is no longer lowered to MIR

Code that's not reachable (e.g. it occurs after an unconditional `return`) is no
longer lowered to MIR. This fixes [this
bug](https://github.com/inko-lang/inko/issues/501), and may slightly improve
compile times when there's a lot of unreachable code.

## Various fixes for type inference

Various issues related to type inference not quite working the way intended have
been solved, such as [this bug](https://github.com/inko-lang/inko/issues/346)
and [this bug](https://github.com/inko-lang/inko/issues/538).

## Working with unique values is now easier

In Inko, the type `uni T` indicates a type for which no aliases exist and can be
created, thereby making it safe to move it between processes. As one can't
create aliases to such types, working with these types [was
difficult](https://github.com/inko-lang/inko/issues/528). Take the following
snippet for example:

```inko
class Config {
  let @ip: uni IpAddress
}

fn example(config: ref Config) -> uni IpAddress {
  recover config.ip.clone
}
```

Code such as this was invalid, as `config` is of type `ref Config`, which isn't
"sendable", meaning it can't be used inside a `recover` or sent to another
process. Typing the `config` variable as `uni Config` wouldn't work either,
because the compiler didn't allow access to fields through `uni T` values.

This release includes
[changes](https://github.com/inko-lang/inko/commit/f8bd2499a6c23c3bb168f9eedfb488385727bbe6)
that make this possible. The way this works is as follows:

We allow temporary aliases to `uni T` called `uni ref T` for immutable
references, and `uni mut T` for mutable references. These aliases can't be
assigned to variables, passed to arguments, aren't compatible with anything, and
you can't send them between processes. This effectively limits them to being
used as receivers for method calls. We then allow methods to be called on such
values with the same restrictions as `uni T` receivers (e.g. all arguments must
be sendable). In addition, we allow access to fields of `uni T` values and
expose them as these references.

In case of the above example, this means `config.ip` returns a `uni ref
IpAddress` (because `config` is a `ref Config`). The `IpAddress` type in turn
doesn't store any references, and `IpAddress.clone` is defined such that it
can't create any references to its returned value that outlive its return value.
This means we can recover the returned `IpAddress` into a `uni IpAddress`.

The end result is that it's now much easier to work with and recover values into
a `uni T`, without the need for annotating return types as `uni T` (unless you
deemed this necessary for other reasons).

## Changes to the standard library

- [`std::iter.join`](https://github.com/inko-lang/inko/commit/c0463c464bf06df432c53147ae587c10c4a8b2c9)
  is moved to `String.join`.
- [`Result.collect`](https://github.com/inko-lang/inko/commit/d85d48af3db8e58a52c4a7f571ea7bcbb7284141)
  is used to turn an `Iter[Result[T, E]]` into a `Result[Array[T], E]`,
  stopping at the first `Error` it encounters.
- [`Iter.last`](https://github.com/inko-lang/inko/commit/5f87a41b6d6cdcac3735886e47ab68969a1e8565)
  returns the last value in an iterator.

## The default build mode now includes optimisations

Instead of defaulting to a debug build, the compiler defaults to a mode that
balances optimisations and compile times, while still including debugging
symbols. This means that `inko build foo.inko` is enough to produce an
executable with good runtime performance, instead of requiring the use of `inko
build --release foo.inko`. The `--opt` flag is used to control the optimisation
level, and supports `none`, `balanced` and `aggressive`. The latter may be used
in the future to enable more aggressive optimisations. As we don't implement any
optimisations for now, all options result in the same kind of executable,
but this will of course change in the future.

## Executables statically link against libgcc

Executables generated for Linux require libgcc, as the Rust runtime library
requires it. Rather than dynamically linking against libgcc, we now [statically
link](https://github.com/inko-lang/inko/commit/3017aa520e06c80410ad2fe34cbe35e47b31e434)
against this library at compile-time. This means the only dependencies the
executable needs are libc, and libm (in case a platform doesn't include this as
part of libc).

## Following and supporting Inko

If Inko sounds like an interesting project, consider joining the [Discord
channel](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

We are working on Inko full-time and using our savings to cover the costs. If
you'd like to support the continued development of Inko, please consider
donating using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse).
Every donation, no matter how small, is greatly appreciated.
