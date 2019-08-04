---
title: Inko 0.2.5 released
date: 2018-09-10 22:00:00 UTC
description: Inko 0.2.5 has been released
---
<!-- vale off -->

Inko 0.2.5 has been released.

<!-- READ MORE -->

## Noteworthy changes in 0.2.5
{:.no_toc}

* TOC
{:toc}

The full list of changes can be found in the [CHANGELOG][changelog].

### Sending unsupported messages is no longer silently ignored

In 0.2.4, a bug was introduced that would prevent the compiler from producing a
compile time error whenever sending a message using an explicit receiver. This
would lead to code such as the following producing a runtime error, instead of a
compile time error:

```inko
'hello'.foo
```

Since this particular bug is rather serious we decided to release a fix in
0.2.5, instead of waiting for 0.3.0.

### Boolean assertions are now easier to define

The addition of `std::test::assert.true` and `std::test::assert.false` will make
it easier to set boolean assertions. For example, instead of this:

```inko
import std::test::assert

assert.equal(10 == 10, True)
```

You can now write the following:

```inko
import std::test::assert

assert.true(10 == 10)
```

[changelog]: https://gitlab.com/inko-lang/inko/blob/v0.2.5/CHANGELOG.md#025-september-11-2018
