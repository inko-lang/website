---
author: Yorick Peterse
title: "Inko 0.13.1 released"
date: "2023-10-14 16:00:00 UTC"
---

We're pleased to announce the release of Inko 0.13.1. This release includes a
new C FFI, specialization of generic types and methods, and more.

<div class="note" markdown="0">
<div class="icon" markdown="0">ℹ️</div>
<div class="text" markdown="1">

While working on the 0.13.0 release we discovered an error that occurs when
building Inko 0.13.0 for ARM64 platforms. This is fixed in 0.13.1, hence the
version jump from 0.12.0 to 0.13.1.

</div>
</div>

## Table of contents
{:.no_toc}

* TOC
{:toc}

This release includes many changes not listed in this announcement. For the full
list of changes, refer to the [changelog](https://github.com/inko-lang/inko/blob/main/CHANGELOG.md#0130-2023-10-14)
for this release.

## A new C FFI and conditional compilation

<div class="note" markdown="0">
<div class="icon" markdown="0">🎉</div>
<div class="text" markdown="1">

Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature

</div>
</div>

With version 0.13.1, Inko once again has a functioning FFI for interacting with
C libraries. The FFI is a compile-time FFI, instead of using e.g.
[libffi](https://sourceware.org/libffi/). We also include support for
conditional compilation at the `import` level.

For example, to use the `ceil()` function from libm, you'd write the following
code:

```inko
# This imports a C library.
import extern "m"

# This "attaches" a function defined in a C library.
fn extern ceil(value: Float64) -> Float64

class async Main {
  fn async main {
    ceil(1.123 as Float64) as Float
  }
}
```

Variadic functions are also supported:

```inko
fn extern printf(format: Pointer[UInt8], ...) -> Int32

class async Main {
  fn async main {
    printf("Hello %s\n".to_pointer, "Inko".to_pointer)
  }
}
```

C libraries imported are linked _dynamically_ by default, but static linking can
be enabled using `inko build --static`. The libc and libm libraries are _always_
linked dynamically, even with the `--static` flag. We dynamically link by
default as many Linux distributions only ship dynamic versions of libraries,
requiring extra work to get the static libraries; assuming they're available in
the first place. Dynamically linking some libraries while statically linking
others isn't supported.

Conditional compilation is used to restrict imports to specific
configurations/platforms. To import a module for 64 bits Linux platforms, you'd
write the following:

```inko
import foo if linux and amd64
```

Conditionally compiled code in arbitrary places (e.g. in the middle of a method)
isn't supported. This keeps the complexity required to make this work
manageable, and forces you to push platform/configuration specific code into
dedicated modules.

For more details, refer to [the FFI documentation](https://docs.inko-lang.org/manual/main/guides/ffi/),
the [conditional compilation documentation](https://docs.inko-lang.org/manual/main/guides/conditional_compilation/),
and/or commit [df66fef7](https://github.com/inko-lang/inko/commit/df66fef7).

## Specialization of types and methods

<div class="note" markdown="0">
<div class="icon" markdown="0">🎉</div>
<div class="text" markdown="1">

Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature

</div>
</div>

Before version 0.13.1, Inko used pointer tagging and runtime checks to handle
generic types. For example, integers used pointer tagging for 63 bits integers
and resort to heap allocating integers that needed the full 64 bits. References
also used pointer tagging, such that generic code could (at runtime) determine
if a value should be dropped, or if its reference count should be adjusted.
Floats were always boxed, requiring a total of 32 bytes for a float (8 bytes for
the pointer, and 24 bytes for the heap allocated value).

As of 0.13.1, the compiler generates specialized versions of generic types and
methods. `Int` and `Float` are no longer boxed, there's no more pointer tagging,
and no more runtime checks.

The implementation uses a slightly different approach from other compilers:
instead of specializing types and methods over every type assigned to a generic
type parameter, types are grouped into "shapes" and we specialize over these
shapes. By grouping types together, we can provide a better balance between fast
compile times and good runtime performance. Unboxed types such as `Int`,
`Float`, `Bool`, and `Nil` get their own shape, and thus their own versions of
types and methods. `String` also gets its own shape. References use two shapes,
one for immutable references and one for mutable references. Owned values are
all grouped into the same shape. This means that for example `Array[User]` and
`Array[Kitten]` use the same specialization of the `Array` type.

Compared to the old runtime approach this new approach results in larger
executables (though this depends on the program in question), but with better
runtime performance.

See [this section in the
documentation](https://docs.inko-lang.org/manual/main/internals/compiler/#generics)
and commit [3057ba7e](https://github.com/inko-lang/inko/commit/3057ba7e) for
more details.

## Private types and methods are private to their namespace

When types and methods are defined as private, they are no longer private to the
module they are defined in. Instead, they are private to the _namespace_ the
surrounding module belongs to. Thus, a type `Foo` defined in `std.foo` is
available to the modules `std.bar`, `std.foo.bar`, but not to `quix.foo`.

This approach allows related modules (e.g. those provided by the standard
library) to depend on shared private types and methods. In addition, it makes it
possible for unit tests to test private types and methods.

See commit [81bae997](https://github.com/inko-lang/inko/commit/81bae997) for
more details.

## Array is implemented in Inko

The `Array` type is implemented entirely in Inko, instead of acting as a wrapper
around a type provided by the Rust-based runtime library. This makes maintenance
easier, allows `Array` types to be specialized, and removes the need for runtime
library calls for array operations, such as pushing a value into the array.

See commit [13e8e557](https://github.com/inko-lang/inko/commit/13e8e557) for
more details.

## "length" is replaced with "size"

Various types expose methods to get the number of values they store. These
methods used to be called "length", but have been renamed to "size". For
`String` methods that operate on extended grapheme clusters, the term "chars" is
used to better reflect that the operation acts on grapheme clusters instead of
bytes.

See commit [2771a63e](https://github.com/inko-lang/inko/commit/2771a63e) for
more details.

## Enum is renamed to Stream

The type `std.iter.Enum` is now called `std.iter.Stream`, to not confuse
users into thinking it's somehow related to enum classes created using `class
enum`.

See commit [70728b63](https://github.com/inko-lang/inko/commit/70728b63) for
more details.

## Reworked parsing and formatting of integers

Instead of using dedicated methods such as `Int.from_base10` and
`Int.from_base16`, parsing is now done using `Int.parse`. The format to parse is
specified using a `std.int.Format` passed as a second argument:

```inko
import std.int.Format

Int.parse('123', Format.Decimal) # => 123
```

The same is true for formatting an `Int`:

```inko
import std.int.Format

123.format(Format.Decimal) # => "123"
```

See commit [95434442](https://github.com/inko-lang/inko/commit/95434442) for
more details.

## Arrays can be sorted

The methods `Array.sort` and `Array.sort_by` have been added. These methods are
used for sorting an `Array` in place, provided the values stored in the `Array`
implement the trait `std.cmp.Compare`:

```inko
let nums = [0, 3, 3, 5, 9, 1]

nums.sort
nums # => [0, 1, 3, 3, 5, 9]
```

The sorting algorithm used by these methods is a stable, recursive merge sort.
While faster stable sorting algorithms exist (e.g. Timsort), they're much more
complicated to implement compared to merge sort, and as such it's easier to
implement them incorrectly. In the future we may switch to a different
algorithm, if this proves necessary.

See commit [31a8a17a](https://github.com/inko-lang/inko/commit/31a8a17a) for
more details.

## Float implements the Compare trait

The `Float` type now implements `std.cmp.Compare` in accordance to the
`totalOrder` predicate as defined in the IEEE 754 (2008 revision) specification.
Per this specification, values are ordered in the following order:

1. negative quiet NaN
1. negative signaling NaN
1. negative infinity
1. negative numbers
1. negative subnormal numbers
1. negative zero
1. positive zero
1. positive subnormal numbers
1. positive numbers
1. positive infinity
1. positive signaling NaN
1. positive quiet NaN

See commit [cf87e5a7](https://github.com/inko-lang/inko/commit/cf87e5a7) for
more details.

## The syntax for imports is changed

The syntax to separate modules and symbols in `import` statements is changed:
instead of `::`, you now have to use `.`:

```inko
# Before:
import std::foo::(A, B)

# After:
import std.foo.(A, B)
```

See commit [8026b29d](https://github.com/inko-lang/inko/commit/8026b29d) for
more details.

## Working with unique values is made a little easier

You can now use `self` in `recover` expressions, and values of type `uni ref T`
/ `uni mut T` (temporary borrows of a `uni T` value) can now be passed to
arguments that expect a `ref T` or `mut T`, if the compiler can guarantee this
is safe. [This issue](https://github.com/inko-lang/inko/issues/570) contains
some more details about this change.

See commits [007495be](https://github.com/inko-lang/inko/commit/007495be) and
[be0d8304](https://github.com/inko-lang/inko/commit/be0d8304) for more details.

## Running `inko pkg init` is no longer necessary

When running package commands that alter the package manifest (`inko.pkg`), you
no longer need to run `inko pkg init` to ensure the manifest file exists, as
these commands now create this file automatically.

See commit [6f7a3780](https://github.com/inko-lang/inko/commit/6f7a3780) for
more details.

## The package manager supports multiple major versions of the same package

The dependency graph of your project can now contain multiple different major
versions for the same package. This means package A can depend on version
1.2.3 of the "json" package, while package B can depend on version 2.3.4 of
the same package. It's not possible for the same package to depend on multiple
different major versions of another package, i.e you can't depend on both
version 1.2.3 and 2.3.4 of the "json" package.

This change makes dependency management less painful, as upgrading a package to
a different major version no longer results in a cascade of major version
updates for any package that depend on it (and so on).

See commit [256e8166](https://github.com/inko-lang/inko/commit/256e8166) for
more details.

## Official support for FreeBSD

Inko now officially supports FreeBSD, and is tested against in our continuous
integration setup. The minimum version we support is 13.2, though older versions
may also work.

We considered also supporting OpenBSD, but decided against it. The effort
required is just not worth it, given the overlap between people using OpenBSD
and people interested in using Inko is likely small or even non-existing.

See commit [ba7217ba](https://github.com/inko-lang/inko/commit/ba7217ba) for
more details.

## The Inko website now lists available third-party packages

While not related to the release itself, but still worth highlighting: the
website now includes a [page that lists available third-party
packages](/packages). While the page is quite basic, it makes discovering Inko
packages a little easier.

## Following and supporting Inko

If Inko sounds like an interesting language, consider joining the [Discord
channel](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/). If you'd like to support
the continued development of Inko, please consider donating using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).

[nlnet]: https://nlnet.nl/
[nlnet-announcement]: /news/inko-0-12-0-released/#header-inko-receives-funding-from-nlnet
