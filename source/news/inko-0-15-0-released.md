---
{
  "title": "Inko 0.15.0 released",
  "date": "2024-06-30T15:00:00Z"
}
---

We're pleased to announce the release of Inko 0.15.0. This release includes
support for automatically formatting source code, generating documentation from
source code, support for handling Unix signals, and much more.

## [Table of contents]{toc-ignore}

::: toc
:::

For the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.15.0/CHANGELOG.md#0150-2024-06-29).

A special thanks to the following people for contributing changes included in
this release:

- [Dimitris Apostolou](https://github.com/rex4539)
- [fres621](https://github.com/fres621)

We'd like to thank the [NLnet foundation][nlnet] for sponsoring part of the work
that went into this release.

## Automatic formatting of source code

::: info
Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature.
:::

Inko 0.15.0 introduces the `inko fmt` command, capable of formatting one or more
source files according to the Inko style guide. This command can either be used
manually from the command-line, or from your editor using the appropriate plugin
(e.g. [conform.nvim](https://github.com/stevearc/conform.nvim) for NeoVim). For
example, we can automatically format messy code such as this:

```inko
import std.stdio(STDOUT)
     import std.net.ip(IpAddress)
  class async Main {
       fn async main {
let addr = IpAddress.v4(
      127,0,0,
      1
    )
    STDOUT.new
      .print(addr
        .to_string)
  }
}
```

Into this:

```inko
import std.net.ip (IpAddress)
import std.stdio (STDOUT)

class async Main {
  fn async main {
    let addr = IpAddress.v4(127, 0, 0, 1)

    STDOUT.new.print(addr.to_string)
  }
}
```

Inko's formatter is an opinionated formatter and offers no configuration
settings to adjust, ensuring that every project using `inko fmt` uses the same
style. Some might argue in favour of being able to configure certain aspects
(e.g. the line length), but the ability to do so only leads to constant
[bike-shedding](https://en.wikipedia.org/wiki/Law_of_triviality).

Users _can_ still control the formatting somewhat, as the formatter retains
empty lines in expression bodies (collapsing multiple empty lines into a single
one). This allows you to visually separate certain blocks of code if deemed
beneficial.

See [the
documentation](https://docs.inko-lang.org/manual/latest/references/style/#using-inko-fmt)
for more details on how to use the new `inko fmt` command.

See commit
[215b63d](https://github.com/inko-lang/inko/commit/215b63dd72c78bbcbef0cd579feccbe228a0fe6f)
for more details, and [this
article](https://yorickpeterse.com/articles/how-to-write-a-code-formatter/) for
details on the algorithm used by the formatter.

## Generating documentation from source code

::: info
Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature.
:::

Starting with Inko 0.15.0, you can generate documentation from your source code.
The `inko doc` command is used to generate a list of JSON files containing
information about the various symbols (e.g. classes) of a program. A separate
program is then used to convert these JSON files into the desired format.
[idoc](https://github.com/inko-lang/idoc) is an official program used to convert
these JSON files to a static HTML website.

idoc is also used to generate the documentation for Inko's standard library,
which is found at the following places:

- [For the `main` branch](https://docs.inko-lang.org/std/main/)
- [For the latest stable release](https://docs.inko-lang.org/std/latest/)
- [For the 0.15.0 release](https://docs.inko-lang.org/std/v0.15.0/)

To use idoc in your own project, run `idoc` and the resulting website is found
at `./build/idoc/public`. To include documentation for dependencies, run `idoc
--dependencies`. In the future we'll also provide a platform to host
documentation for Inko packages, such that you don't need to generate this
yourself. See [this issue](https://github.com/inko-lang/inko/issues/726) for
more details.

For more information about generating documentation (such as how to install
idoc), refer to [the documentation](https://docs.inko-lang.org/manual/v0.15.0/references/documentation/),
or take a look at commit
[cefa664](https://github.com/inko-lang/inko/commit/cefa6649c7959ee293e118bb1f2dd9e53d86781d).

## Support for handling Unix signals

Inko 0.15.0 introduces the type
[`std.signal.Signal`](https://docs.inko-lang.org/std/v0.15.0/module/std/signal/Signal/).
This type is used to block the current process (not the OS thread) until a given
Unix signal is received. For example, to wait for the `SIGUSR1` signal, one uses
it as follows:

```inko
import std.signal (Signal)

class async Main {
  fn async main {
    Signal.User1.wait
  }
}
```

Signal support is implemented by using a dedicated thread that calls
`sigwait(3)`, with all the registered signals, rescheduling the appropriate
processes when their desired signal is received.

For more information, refer to the following:

- The documentation of
  [`std.signal.Signal`](https://docs.inko-lang.org/std/v0.15.0/module/std/signal/Signal/)
- [The
  documentation](https://docs.inko-lang.org/manual/v0.15.0/design/runtime/#signal-handling)
  on how signal handling is implemented in the runtime
- Commit [1d4bad2](https://github.com/inko-lang/inko/commit/1d4bad250a69a7d402249761e7a13492e8a0ea18)

## Parsing of command-line options

The standard library now includes the module
[`std.optparse`](https://docs.inko-lang.org/std/v0.15.0/module/std/optparse/),
used for parsing command-line options. For example, to parse a `--help` option
one writes the following:

```inko
import std.env
import std.optparse (Options)

class async Main {
  fn async main {
    let opts = Options.new

    opts.flag('h', 'help', 'Show this help message')

    let matches = opts.parse(env.arguments).get
  }
}
```

See commit
[0fb6d0a](https://github.com/inko-lang/inko/commit/0fb6d0a57e981386927a3953e5a10b045e2dfb76)
for more details.

## Support for compile-time variables

If a constant is defined using `let pub` and of type `String`, `Int` or `Bool`,
you can overwrite its value at compile-time using `inko build --define`. This
allows you to change certain parts of a program without having to change its
source code, such as the directory it loads certain files from. For example:

```inko
let pub PATH = '/usr/share/example'

class async Main {
  fn async main {}
}
```

To change `PATH` to `/usr/local/share/example`, we compile the program as
follows:

```bash
inko build --define main.PATH=/usr/local/share/example
```

For more information, refer to [the
documentation](https://docs.inko-lang.org/manual/v0.15.0/guides/compile-time-variables/)
and commit
[3298ae2](https://github.com/inko-lang/inko/commit/3298ae2f8c77cad8dce2d80700fc87b19efa789a)
for more details.

## Improvements to interacting with C code

The `Main` process now always runs on the main OS thread. This makes it possible
to interact with C code that uses thread-local state and expects code to run on
the same thread, such as most GUI frameworks.

In addition, module methods defined using the `extern` keyword can be passed as
callbacks to C functions using the syntax `mut method_name`. For example:

```inko
# This guarantees this method uses the C calling convention.
fn extern example(value: Int) -> Int {
  value
}
class async Main {
  fn async main {
    let pointer_to_method = mut example
  }
}
```

Here `pointer_to_method` is a pointer to the `example` method, not a borrow.

See commits [0f68a92](https://github.com/inko-lang/inko/commit/0f68a92fce4eef175aff9962e216b5423686a76c)
and [01bd04e](https://github.com/inko-lang/inko/commit/01bd04ef722faea8b9cf927f01f76c60e805e625)
for more details.

## Renaming of error handling methods

The following methods are renamed:

- `unwrap` (e.g. `Option.unwrap`) is renamed to `get` (e.g. `Option.get`)
- `unwrap_or` is renamed to just `or`
- `unwrap_or_else` is renamed to `or_else`
- `expect` is renamed to `or_panic`

This means that instead of this:

```inko
let x = Option.Some(42)

x.expect('a Some is expected')
```

You now write this:

```inko
let x = Option.Some(42)

x.or_panic('a Some is expected')
```

## The drop order of fields and constructor arguments is changed

Instead of dropping fields and constructor arguments in definition order,
they're now dropped in reverse-definition order to match the order used when
dropping local variables. If you are experiencing drop panics when upgrading to
Inko 0.15.0, you'll likely need to change the definition order of the relevant
fields to resolve this.

See commit [9ce4f9e](https://github.com/inko-lang/inko/commit/9ce4f9e1c56799307d124d6e365b302151f3a223)
for more details.

## TCP\_NODELAY is enabled for TCP sockets

When using
[`std.net.socket.TcpClient`](https://docs.inko-lang.org/std/v0.15.0/module/std/net/socket/TcpClient/)
and
[`std.net.socket.TcpServer`](https://docs.inko-lang.org/std/v0.15.0/module/std/net/socket/TcpServer/),
the `TCP_NODELAY` option is set automatically. This option is enabled because
_not_ enabling it can lead to latency issues when using TCP sockets. In the rare
case that this option must be disabled, one can do so using
[`std.net.socket.Socket.no_delay=`](https://docs.inko-lang.org/std/v0.15.0/module/std/net/socket/Socket/#method.no_delay=).

See commit
[740682c](https://github.com/inko-lang/inko/commit/740682cbaed641d95a4388d1ebbead455e0996e2)
and [this article](https://brooker.co.za/blog/2024/05/09/nagle.html) for more
details.

## Syntax changes

### Strings

Whitespace in string literals can no longer be escaped like so:

```inko
let x = 'foo \
bar'
```

Before 0.15.0 this would result in the string value `foo bar`, but starting with
0.15.0 this is now a syntax error. The reason for this is that the presence of
these escapes complicates the parser too much, it makes automatic code
formatting difficult, and it's not _that_ useful as you can do the following
instead:

```inko
let x = 'foo ' + 'bar'
```

See commit [dc87e18](https://github.com/inko-lang/inko/commit/dc87e18152a522c3eb341e9b9c898bee88afcc36)
for more details.

### Imports

The import syntax is changed such that a `.` is no longer needed between the
module and the symbol list. In addition, symbols must always be surrounded by
parentheses, even when importing only a single symbol:

```inko
# Before:
import a.b.c.A
import a.b.c.(A, B)

# After:
import a.b.c (A)
import a.b.c (A, B)
```

See commit [41a0b3e](https://github.com/inko-lang/inko/commit/41a0b3e567a31900e1796fb6a660255bf1c5b2e6)
for more details.

### Class literal syntax

The syntax to create an instance of a class is changed, instead of this:

```inko
class Person {
  let @name: String
}

Person { @name = 'Alice' }
```

You write this instead:

```inko
class Person {
  let @name: String
}

Person(name: 'Alice')
```

The old syntax is still supported and `inko fmt` updates it to the new syntax
automatically, but support will be removed in the next release.

See commit [b7bcf46](https://github.com/inko-lang/inko/commit/b7bcf46ead3b1ecb83e5e3ad38777d626fc9f96f)
for more details.

### Trailing closure syntax

Inko supported the following syntax for closures, provided the closure is the
last argument:

```inko
foo(10, 20) fn { ... }
```

Support for this syntax will be removed in 0.16.0, and `inko fmt` changes it to
the following:

```inko
foo(10, 20, fn { ... })
```

This new syntax makes both parsing and formatting (much) simpler compared to the
old syntax.

## LLVM 16 is now required

Inko 0.15.0 requires LLVM 16, and no longer supports LLVM 15. We plan to upgrade
to LLVM 17 as part of the next release.

See commit [a35d4ec](https://github.com/inko-lang/inko/commit/a35d4ec288b90133a983fc0e27bb07b6d05ae6da)
for more details.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/). If you'd like to support
the continued development of Inko, please consider donating using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).

[nlnet]: https://nlnet.nl/
[nlnet-announcement]: /news/inko-0-12-0-released/#inko-receives-funding-from-nlnet
