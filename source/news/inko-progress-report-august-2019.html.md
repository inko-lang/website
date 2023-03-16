---
author: Yorick Peterse
title: "Inko Progress Report: August 2019"
date: "2019-09-03 14:47:16 UTC"
---

The progress report for August 2019 is here! This month was all about porting
over the Inko parser from Ruby to Inko, though we also made various small
improvements.

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

## Array and hash map literal changes

As we mentioned in our [progress report for July 2019][july-report], in August
we planned to make various syntax changes for hash map and array literals.
Having put more thought into it, we decided to remove both hash map and array
literals, and instead rely on the message sending syntax. We also renamed the
`HashMap` type to `Map`.

For arrays you now have to use `Array.new` like so:

```inko
Array.new(10, 20, 30) # The same as the old [10, 20, 30] syntax
```

For hash maps, the approach is a little different. The initial idea was to use
syntax like this:

```inko
Map.new(key1: value1, key2: value2)

# Alternatively:
Map.new(key1 -> value1, key2 -> value2)
```

Here `:` or `->` would be a method that returns a tuple of sorts containing the
receiver (the key) and its argument (the value). This approach proved
problematic for several reasons:

1. Using `:` would not work as this conflicts with the syntax for keyword
   arguments. Using `->` is not ideal since it's already used to specify return
   types, which could be confusing to users.
1. We would have to introduce some kind of tuple type for _just_ this use case,
   which felt like the wrong approach. Supporting tuples with more than just two
   values would require extensive changes to the compiler.
1. The Ruby compiler's type system is a bit buggy, which meant that we would
   have to write quite a bit of ugly code to get things working.
1. The approach is wasteful when it comes to memory, as we are allocating tuples
   only to throw them away moments later.

Instead of going down a rabbit hole to try and fix all this, we instead
introduced a new method: `Map.set`. This method is like `Map.[]=` in that it
sets a key to a value, but unlike `Map.[]=` it returns the map itself; instead
of the value the key is set to. Using this method you can create a `Map` with a
set of key-value pairs like so:

```inko
Map
  .new
  .set('name', 'Alice')
  .set('city', 'Amsterdam')
```

While this approach is a bit more verbose than using special syntax, it does not
require any compiler changes. This approach is not unique to Inko, as some
functional programming languages use a similar approach to setting key-value
pairs.

For more information about these changes you can refer to the following commits:

* <https://github.com/inko-lang/inko/commit/94ac7d14de445b3df4f97ad4967868f99e4a2e14>
* <https://github.com/inko-lang/inko/commit/c94fb713b12e8ecf7ecfab34e936d824cea60fae>

## Porting the parser to Inko

In August we spent a lot of time on porting over the Inko parser from Ruby to
Inko. As part of this, we removed support for "newline sends" (for a lack of a
better name). This syntax would allow you to write the following:

```inko
foo == bar
  .if_true {
    # ...
  }
```

The parser would then parse this as follows:

```inko
(foo == bar).if_true {
  # ...
}
```

Supporting this has always been tricky and could be confusing at times,
in particular when trying to wrap the right-hand side of a binary expression.
Instead of trying to find a way to support this without making things too
complex, support for this was removed all together. This means that to send a
message to the result of a binary expression (e.g. `foo == bar`), you now have
to wrap said expression in parentheses.

The Inko parser also comes with stricter parsing for arguments without
parentheses. Instead of supporting arbitrary expressions, you can now only pass
a single block as an argument when leaving out parentheses. When passing
multiple arguments you must use parentheses. This means that this is no longer
valid:

```inko
User.create name: 'Alice', age: 30
```

This is still valid:

```inko
users.each do (user) {
  # ...
}
```

These changes make it much easier to parse arguments passed with a message, and
should lead to more consistent code.

## Windows CI Support

In August we completed the work of setting up GitLab CI on Windows, and stopped
using AppVeyor. All tests now run on Linux, macOS, and Windows 2019. Merge
requests submitted from forks only run tests on Linux, as our macOS and Windows
runners can not be shared with forks.

## Smaller binary sizes

In merge request ["Reduce the VM binary size a bit"][mr75] we made some small
changes that reduce the size of the VM binary by about 100 KB when including
debugging symbols, and by about 10 KB when stripping debugging symbols. When
compiling with [Link Time Optimisation][lto], the VM executable will now be
1.3 MB in size; small enough to fit on a 1.4MB floppy disk!

While these changes are not significant, we hope to combine them with future
changes to keep the VM executable size under 1.5 MB.

## Improved performance for writing to STDOUT and STDERR

[Mohamad Barbar][mbarbar] [submitted a merge request][mr77] that improved
performance of writing to STDOUT and STDERR. This improvement is achieved by
directly using the STDOUT and STDERR VM instructions. For Inko's test suite
these changes reduce the total runtime by about 5 milliseconds.

## Improved output of test failures

The output of test failures has been improved a bit so that it becomes easier to
see where the failure occurred, and where the failing test is defined. We also
split the group and test names into separate fields, as combining these can lead
to sentences that are a bit awkward to read.

The old output looks like this:

```
Test: std::compiler::lexer::Lexer.next Lexing an identifier followed by a trailing newline
Location: runtime/tests/test/std/compiler/test_lexer.inko:1382

Expected "identifier" to equal "identifierx"
```

The new output looks like this:

```
Group:            std::compiler::lexer::Lexer.next
Test:             Lexing an identifier followed by a trailing newline
Test location:    runtime/tests/test/std/compiler/test_lexer.inko:1378
Failure location: runtime/tests/test/std/compiler/test_lexer.inko:1382
Failure:          Expected "identifier" to equal "identifierx"
```

## Plans for September

In September we will continue working on the parser. Based on the progress made
during the month we may decide to release version 0.5.0 without the Inko parser,
as it has been a while since the last release of Inko.

If you would like to support the development of Inko, please [donate to Inko on
Open Collective][open-collective]. If you would like to donate via other means,
please send an Email to <mailto:yorick@yorickpeterse.com>.

[july-report]: /news/inko-progress-report-july-2019/
[mr75]: https://gitlab.com/inko-lang/inko/merge_requests/75
[lto]: https://en.wikipedia.org/wiki/Interprocedural_optimization
[mr77]: https://gitlab.com/inko-lang/inko/merge_requests/77
[mbarbar]: https://gitlab.com/mbarbar
[open-collective]: https://opencollective.com/inko-lang
