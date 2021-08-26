---
title: Inko 0.7.0 has been released
date: 2020-08-04 21:37:55 UTC
---

Inko 0.7.0 has been released, featuring improved garbage collection performance,
additions to the standard library, support for circular types, and static typing
instead of gradual typing.

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

For the full list of changes, take a look at
[the changelog](https://gitlab.com/inko-lang/inko/-/blob/7c955324671da3897041f156ac08019086ed250d/CHANGELOG.md#070-august-04-2020).

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/).

If you would like to engage with others interested in the development of Inko,
please join the [Matrix chat
channel](https://app.element.io/#/room/#inko-lang:matrix.org). You can also follow
the development on [Reddit](https://www.reddit.com/r/inko/), or follow the
author of Inko on [Twitter](https://twitter.com/yorickpeterse). For more
information check out the [Community](/community) page.

## Improved garbage collection performance

Tracing live objects during garbage collection is done more efficiently, and
blocks of memory used by the allocator are stored more efficiently.

## Standard library additions

The following types and methods have been added to the standard library:

* `std::array::Array.join`
* `std::array::Array.reverse_iter`
* `std::boolean::Boolean.false?`
* `std::boolean::Boolean.true?`
* `std::fs::path::Path.directory`
* `std::set::Set`
* `std::string::String.slice_bytes`
* `std::string::String.split`

## Support for circular types

The Inko (Ruby) compiler now supports circular types, allow code such as the
following:

```inko
object A {
  @b: B
}

object B {
  @a: A
}
```

## Static typing instead of gradual typing

Inko is now a statically typed language, instead of a dynamically typed
language. The `Dynamic` type has been replaced with a trait called `Any`,
implemented by all types. Unlike the `Dynamic` type, this trait does not allow
you to send any message to it to get another `Dynamic` in return. Instead,
you'll need to somehow check the type at runtime supports the operations you
wish to perform.

Inko's syntax has also been changed in response to the removal of gradual
typing. For example, method arguments are now required to either specify a type
or a default value; leaving out both is no longer valid.

For more details on these changes, refer to [this
section](/news/static-typing-pattern-matching-and-inkos-self-hosting-compiler/#header-inko-is-now-statically-typed)
from the article ["Static typing, pattern matching, and Inko's self-hosting
compiler
"](/news/static-typing-pattern-matching-and-inkos-self-hosting-compiler/).

## ByteArray in the prelude

The `ByteArray` type is now in the prelude, removing the need to import it using
`import std::byte_array::ByteArray`. The use of byte arrays is common, so this
makes it less frustrating to use them.

## std::mirror is now optional

The module `std::mirror` is used for runtime reflection of objects. It's also
used to format objects in a way readable by humans. Before Inko 0.7.0, this
module was always imported as methods such as `inspect` made use of it.

Starting with Inko 0.7.0, this module is optional and not imported by default.
This also means that pretty-printing objects requires you to first import this
module. Instead of this:

```inko
10.inspect
```

You now have to write this:

```inko
import std::mirror

10.mirror.inspect
```

## Virtual machine instructions use less memory

Before Inko 0.7.0, all VM instructions used at least 32 bytes of memory.
Instruction arguments were stored in a separate vector. In Inko 0.7.0,
instructions have a fixed size of 16 bytes and no longer store their arguments
in a separate vector; instead storing them directly in the instruction itself.

This new setup allows for up to six arguments per instruction. Some instructions
need more than that. For example, when creating an Array the `SetArray`
instruction may need more than six arguments. To make this possible, this
instruction (and several other ones that also need variable arguments) expects
two arguments in the instruction:

1. An argument specifying the number of arguments.
1. An argument specifying the register containing the first argument.

These instructions then expect all arguments to be in a contiguous order. They
will then read the given number of registers in-order, starting with the first
one specified.

To help understand this, imagine the following: we want to create an Array with
4 values, stored in registers 0, 1, 2, and 3. The result is to be stored in
register 4. Before Inko 0.7.0, the `SetArray` instruction layout would be as
follows:

    SetArray 4, 0, 1, 2, 3
             ^  ~~~~~~~~~~> The value registers, each as a separate argument
             |
      The target register

In Inko 0.7.0, the instruction layout instead is as follows:

    SetArray 4, 4, 0
             ^  ^  ^
             |  |  |
             |  |  +---------- The register containing the first value
             |  +------- The number of arguments
             +---- The target register

This allows instructions to accept a variable number of arguments, without
increasing the size of all instructions.

For Inko's own standard library test suite, these changes reduced peak memory
consumption from 27 MB RSS to 21 MB RSS.

## Keyword and variable arguments are handled by the compiler

Making Inko statically typed allowed us to remove virtual machine support for
keyword arguments, variable arguments, and argument count validations. This
simplifies the virtual machine, and makes method calls more efficient. Both
keyword arguments and variable arguments are now handled solely by the compiler.
