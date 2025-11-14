---
{
  "title": "Inko 0.19.1 is released",
  "date": "2025-11-14"
}
---

We're pleased to announce the release of Inko 0.19.1. This release includes
support for HTTP servers and clients, pattern matching for let expressions,
better code generation, many fixes and performance improvements, and more!

If you're new to Inko: Inko is a programming language for building concurrent
software, but without the usual headaches such as data race conditions and
non-deterministic garbage collectors. Inko features deterministic automatic
memory management, compiles to machine code using LLVM, supports different
platforms (Linux, macOS and FreeBSD, and potentially any other Unix based
platform), and is easy to get started with. For more information, refer to the
[homepage](/) or the [manual](https://docs.inko-lang.org/manual/v0.19.1/).


## [Table of contents]{toc-ignore}

::: toc
:::

This release includes _a lot_ of changes not included in this announcement. For
the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.19.1/CHANGELOG.md#0191-2025-11-13).

A special thanks to the following people for contributing changes included in
this release:

- [Keithcat1](https://github.com/Keithcat1)
- [fres621](https://github.com/fres621)
- [lupuchard](https://github.com/lupuchard)
- [r0nsha](https://github.com/r0nsha)

## HTTP clients, servers, WebSockets and more!

One of the biggest changes included in this release is support for HTTP 1.1
servers, clients, server-sent events, WebSockets, URI parsing and generating,
parsing of MIME types, and various other additions to the standard library to
support the new HTTP 1.1 stack. All this is written in Inko itself, without a
single line of C code!

The HTTP stack is compliant with the various HTTP related RFCs such as:

- [HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
- [HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112)
- [HTTP State Management Mechanism](https://www.rfc-editor.org/rfc/rfc6265)
- [Returning Values from Forms: multipart/form-data](https://www.rfc-editor.org/rfc/rfc7578.html)
- [The Basic HTTP Authentication Scheme](https://www.rfc-editor.org/rfc/rfc7617.html)

Support for WebSockets is implemented in compliance with [RFC
6455](https://datatracker.ietf.org/doc/html/rfc6455) and passes the
[Autobahn](https://websocket.org/guides/testing/autobahn/) test suite (minus
support for compression which isn't implemented).

Let's take a look at these changes, starting with the HTTP client:

```inko
import std.net.http.client (Client)
import std.stdio (Stdout)
import std.uri (Uri)

type async Main {
  fn async main {
    let client = Client.new
    let uri = Uri.parse('https://httpbun.com/get').or_panic
    let res = client.get(uri).send.or_panic
    let buf = ByteArray.new
    let _ = res.body.read_all(buf).or_panic

    Stdout.new.print(buf)
  }
}
```

This produces the following output:

```json
{
  "method": "GET",
  "args": {},
  "headers": {
    "Accept-Encoding": "gzip",
    "Host": "httpbun.com",
    "User-Agent": "inko/0.19.1 (https://inko-lang.org)",
    "Via": "1.1 Caddy"
  },
  "origin": "86.93.96.67",
  "url": "https://httpbun.com/get",
  "form": {},
  "data": "",
  "json": null,
  "files": {}
}
```

The HTTP client transparently supports both HTTP and HTTPS, and supports the
HTTP 1.1 keep-alive mechanism. You can also establish a WebSocket connection
using a `Client`:

```inko
import std.fmt (fmt)
import std.net.http.client (Client)
import std.stdio (Stdout)
import std.uri (Uri)

type async Main {
  fn async main {
    let client = Client.new
    let uri = Uri.parse('https://echo.websocket.org').or_panic
    let (sock, _response) = client.websocket(uri).send.or_panic

    let _ = sock.receive.or_panic
    let _ = sock.text('hello').or_panic

    Stdout.new.print(fmt(sock.receive))
  }
}
```

This produces the following output:

```
Ok(Text("hello"))
```

For more information, refer to the documentation of the [Client
type](https://docs.inko-lang.org/std/v0.19.1/module/std/net/http/client/Client/).

Now let's say we want to create a simple HTTP server. We can do so as follows:

```inko
import std.net.http.server (Handle, Request, Response, Server)

type async Main {
  fn async main {
    Server.new(fn { recover App() }).start(8_000).or_panic
  }
}

type App {}

impl Handle for App {
  fn pub mut handle(request: mut Request) -> Response {
    Response.new.string('hello')
  }
}
```

This starts a server that listens on 0.0.0.0 using port 8000. For each request
the server responds with the following:

```
HTTP/1.1 200
connection: keep-alive
date: Fri, 14 Nov 2025 17:48:52 GMT
content-length: 5

hello
```

The API offered by the standard library is a more low-level API compared to the
usual full-stack frameworks you may be used to. While this means it requires a
bit more work compared to such frameworks, it also gives to you greater control
and flexibility. Even so, the new `std.net.http.server` module has plenty to
offer. For example, here's how you would serve all files in the current working
directory as static files under the path `/static`, supporting both GET and HEAD
requests:

```inko
import std.env
import std.net.http.server (
  Directory, Handle, Request, Response, Server, head_request,
)

type async Main {
  fn async main {
    let pwd = env.working_directory.or_panic

    Server
      .new(fn { recover App(directory: Directory.new(pwd.clone)) })
      .start(8_000)
      .or_panic
  }
}

type App {
  let @directory: Directory

  fn mut route(request: mut Request) -> Response {
    match request.path.split_first {
      case Some(('static', path)) -> return @directory.handle(request, path)
      case _ -> {}
    }

    match request.target {
      case [] -> Response.new.string('home')
      case _ -> Response.not_found
    }
  }
}

impl Handle for App {
  fn pub mut handle(request: mut Request) -> Response {
    head_request(request, route(request))
  }
}
```

For more information, refer to the documentation of the [`std.net.http.server`
module](https://docs.inko-lang.org/std/v0.19.1/module/std/net/http/server/).

## Random number generation in pure Inko

The module `std.rand` used to be implemented on top of the Rust
[rand](https://github.com/rust-random/rand). While this worked, the setup
introduced unnecessary overhead and required a non-trivial amount of Rust
dependencies.

In 0.19.1 the `std.rand` module is implemented entirely in Inko and the rand
dependency is removed. The implementation uses ChaCha based on [this
document](https://github.com/C2SP/C2SP/blob/main/chacha8rand.md) and is seeded
using the operating system's native random number generator (e.g.
`getrandom()` on Linux).

While the API remains the same as before, this reduces compile times of the
runtime library (written in Rust), reduces the amount of dependencies and gives
us greater control over the implementation.

## A more flexible Read/Write API

The `Read` and `Write` traits are implemented by types that wish to provide a
consistent API for reading from and writing to IO streams such as sockets and
files. These traits required that such types produce
[`std.io.Error`](https://docs.inko-lang.org/std/v0.19.1/module/std/io/Error/)
errors when encountering an error. This approach is limiting and overly rigid as
not all kinds of errors can be expresses as a simple IO error.

0.19.1 changes this by making `Read` and `Write` generic over the error type.
For example, instead of implementing `Read` like this:

```inko
impl Read for MyType {
  fn pub mut read(into: mut ByteArray, size: Int) -> Result[Int, Error] {
    ...
  }
}
```

You now implement it like so:

```inko
impl Read[MyError] for MyType {
  fn pub mut read(into: mut ByteArray, size: Int) -> Result[Int, MyError] {
    ...
  }
}
```

If you don't need a dedicated error type you can just implement `Read` and
`Write` over the `std.io.Error` type, and indeed various types in the standard
library do just that.

As part of this change the `Write` trait is also simplified: instead of
requiring types to implement both a `write_string` and `write_bytes` method, the
trait is now defined as follows:

```inko
trait pub Write[E] {
  fn pub mut write[B: Bytes](bytes: ref B) -> Result[Nil, E]

  fn pub mut flush -> Result[Nil, E]
}
```

Here the [`Bytes`
trait](https://docs.inko-lang.org/std/v0.19.1/module/std/bytes/Bytes/) is
implemented by types such as `String`, `ByteArray`, `Slice[String]` and
`Slice[ByteArray]`, meaning only a single method is needed to support writing
these different types to an IO stream. Just like the `Read` trait the `Write`
trait is also generic over the error type.

## A new indexing API

Types such as `Array`, `Map` can be indexed using different values (integers for
`Array`, the keys for a `Map`, etc). For this these types offered various
methods such as `Map.get`, `Map.get_mut`, `Map.opt`, `Map.opt_mut`, and possibly
more.

As part of this release these methods are unified into the following methods:

- `get`: returns an immutable borrow of an index as a `Result[T, E]` where `T`
  is the type of the value and `E` an error type (which varies based on what
  you're indexing)
- `get_mut`: does the same but returns a mutable borrow

This means these types no longer provide a method to perform the operation and
panic if the index is out of bounds or the key doesn't exist. Not only does this
reduce the amount of methods each type needs to provide, it also makes it more
explicit when code may panic. For example, instead of this:

```inko
[10, 20, 30].get(1) # => 20
```

You now write this:

```inko
[10, 20, 30].get(1).or_panic # => 20
```

The changes you may need to make to update your code are as follows:

|=
| Before
| After
|-
| `x.get(y)`
| `x.get(y).or_panic`
|-
| `x.get_mut(y)`
| `x.get_mut(y).or_panic`
|-
| `x.opt(y)`
| `x.get(y)`
|-
| `x.opt_mut(y)`
| `x.get_mut(y)`
|-
| `x.remove_at(y)`
| `x.remove_at(y).or_panic`
|-
| `x.remove(y)`
| `x.remove(y).or_panic`
|-
| `x.byte(y)`
| `x.get(y).or_panic`

Since the `get` and `get_mut` methods return a `Result` instead of an `Option`,
you may also need to use `Result.ok` to transform the `Result` into an `Option`
(if you actually need an `Option` that is). The reason this new API uses a
`Result` is so we can encode extra information into the error type, such as the
index or key that was accessed.

## A new slicing API

This release introduces a new API for slicing `String`, `ByteArray` and `Array`.
These slices are "views" into a range of the underlying type, rather than a copy
of the underlying data. For example, to slice a `String` without copying
anything you'd write something like this:

```inko
'hello world'.slice(start: 0, end: 5)           # => Slice[String]
'hello world'.slice(start: 0, end: 5).to_string # => 'hello'
```

For `String` and `ByteArray` the returned slices are _byte_ slices. This means
that if you want to for example iterate over the grapheme clusters in a
`Slice[String]` you have to first create a new `String` to ensure the data is
valid UTF-8.

Various APIs that produced slice-like data but allocated new values (e.g. a new
`String`) now use the new slicing APIs. For example, `std.fs.path.Path.tail` is
used to return the file name plus extension of a file path. This method used to
return a newly allocated `String`, but now returns a `Slice[String]`.

As part of this change the `match` expression supports pattern matching
`String` literals against `Slice[String]` values, allowing you to write code
such as the following:

```inko
import std.stdio (Stdout)

type async Main {
  fn async main {
    let out = Stdout.new

    match 'foo/bar/baz.txt'.to_path.tail {
      case 'baz.txt' -> out.print('yay')
      case _ -> out.print('nay')
    }
  }
}
```

This will print "yay" to STDOUT.

The slicing API is still new and there are areas where we're still trying to
figure out what the best approach is. For example, if you want a value that's
either a `String`, `ByteArray` or a slice over such values _and_ you need the
various methods provided by the `Slice` type, you have to use the `ToSlice` and
`Bytes` traits like so:

```inko
import std.bytes (Bytes, ToSlice)
import std.stdio (Stdout)

fn example[B: Bytes, S: ToSlice[B]](value: ref S) -> String {
  value.to_slice.slice(0, 5).to_string
}

type async Main {
  fn async main {
    let out = Stdout.new
    let _ = out.print(example('hello'))               # => 'hello'
    let _ = out.print(example('hello'.to_byte_array)) # => 'hello'
    let _ = out.print(example('hello'.to_slice))      # => 'hello'
  }
}
```

We hope to improve this API over time with more methods and an easier way to
abstract over the different slice-like values.

## let pattern matching

`let` expressions now support pattern matching instead of only being able to
define a binding with a value:

```inko
let (name, age) = ('Alice', 42)

name # => 'Alice'
age  # => 42
```

If the pattern isn't exhaustive, you need to add an `else` branch that must
diverge (i.e. return) from the surrounding method:

```inko
let Some(value) = Option.Some(42) else return

value # => 42
```

The `else` branch can also contain multiple expressions:


```inko
let Some(value) = Option.Some(42) else {
  foo
  bar
  return
}

value # => 42
```

In particular, using pattern matching in `let` is useful when unpacking tuples
into separate values, something that gets a little clunky when using a `match`
expression due to the indentation it introduces:

```inko
# So you can write this:
let (name, age) = ('Alice', 42)

out.print(name)
...

# Instead of this:
match ('Alice', 42) {
  case (name, age) -> {
    out.print(name)
    ...
  }
}
```

## for loops

This release introduces `for` expressions for looping over iterators and removes
related methods such as `Iter.each` and `Iter.try_each` in favor of this new
expression. This means that instead of this:

```inko
[10, 20, 30, 40].into_iter.each(fn (num) { out.print(num.to_string) })
```

You now write this:

```inko
for num in [10, 20, 30, 40] { out.print(num.to_string) }
```

If you don't want to take ownership of the value you're iterating over you'll
need to manually convert it to the appropriate iterator. For example:


```inko
let nums = [10, 20, 30, 40]

for num in nums.iter { out.print(num.to_string) }

nums.size # => 4
```

The new `for` expression supports pattern matching as well:

```inko
for (key, val) in [('name', 'Alice'), ('age', '42')] {
  let _ = out.print(key)
  let _ = out.print(val)
}
```

The `for` expression is syntax sugar for a `loop` and `match` and essentially
compiles to the following:

```inko
let _iter = [10, 20, 30, 40].into_iter

loop {
  match _iter.next {
    case Some(num) -> out.print(num.to_string)
    case _ -> break
  }
}
```

## The return of async and await

[0.10.0](/news/inko-0-10-0-released/) introduced `async` expressions and
defaulted to awaiting the result of sending `async` messages. This was removed
in [0.11.0](/news/inko-0-11-0-released) in favor of using the `Future` and
`Channel` types directly.

This release reintroduces the `async` expression and introduces the new `await`
expression. Both these expressions are syntax sugar for `match` expressions and
the existing `Future` and `Promise` types. Take this code for example:

```inko
import std.stdio (Stdout)
import std.sync (Future, Promise)

type async Number {
  fn async get(promise: uni Promise[Int]) {
    promise.set(42)
  }
}

type async Main {
  fn async main {
    let out = Stdout.new
    let (fut, prom) = Future.new

    Number().get(prom)
    out.print(fut.get.to_string)
  }
}
```

This starts a new `Number` process and gives it a `Promise` to resolve to an
`Int`. The `Main` process then waits for that to happen and prints the result.
That's quite a lot of code for such a basic example! We can simplify this using
`async` and `await`, starting with `async`:

```inko
import std.stdio (Stdout)
import std.sync (Promise)

type async Number {
  fn async get(promise: uni Promise[Int]) {
    promise.set(42)
  }
}

type async Main {
  fn async main {
    let out = Stdout.new
    let fut = async Number().get

    out.print(fut.get.to_string)
  }
}
```

Here the `async` expression is compiled such that it passes a `Promise` as the
first argument to `Number.get` and returns a `Future` to resolve. If you want to
wait for the result right away, you can simplify this further using `await`:

```inko
import std.stdio (Stdout)
import std.sync (Promise)

type async Number {
  fn async get(promise: uni Promise[Int]) {
    promise.set(42)
  }
}

type async Main {
  fn async main {
    let out = Stdout.new
    let num = await Number().get

    out.print(num.to_string)
  }
}
```

In most cases this means you only need to import the `Promise` type and you're
good to go. Nice!

## Field assignments for inline and copy types through owned references

[0.18.1](/news/inko-0-18-1-is-released/) introduced support for stack allocated
types, but didn't allow fields of such types to be assigned new values. In
0.19.1 this is now allowed but _only_ through owned references. This limitation
is in place due to how borrowing of stack allocated data works: it creates a
copy of the data that resides on the stack. This means that if you were to
assign a field a new value using a borrow as the receiver, only that borrow
would see the new value.

While this can still happen when you assign a field a new value using an owned
reference (as existing borrows won't see the new field value), it's a little
more explicit and should be less confusing.

One area where this new feature is useful is for builder types. For example, the
type `std.net.http.server.CacheControl` is used for building `Cache-Control`
headers and is an `inline` type. It's API is such that you assign its fields new
values using moving methods like so:

```inko
CacheControl.new.no_revalidate.no_cache.no_store.to_string
```

The combination of this type being an `inline` type and field assignments being
allowed through owned references means that builder types such as `CacheControl`
don't need to be heap allocated, reducing the cost of using them.

## Creating new projects is now easier

The `inko` CLI now includes an `init` command to create a basic project setup.
For example, to create a project for an executable you run `inko init NAME`,
while for a library you use `inko init --lib NAME`. There's also a `--github`
option to automatically create a configuration file for GitHub Actions. For
example:

```bash
inko init example --github
```

This results in the following project structure:

```
example
├── .github
│   └── workflows
│       └── push.yml
├── .gitignore
├── inko.pkg
├── src
│   └── example.inko
└── test
    └── .gitkeep
```

Neat!

## A new backend for TLS cryptography

Inko uses [rustls](https://github.com/rustls/rustls) as its TLS backend. The
rustls library in turn requires a Rust library/backend for various cryptographic
primitives. In case of Inko this backend was
[ring](https://github.com/briansmith/ring). Unfortunately, ring's maintenance
has been spotty with the author even announcing they [were taking a
break](https://github.com/briansmith/ring/discussions/2414). While ring is sort
of maintained again, its future is unclear. In addition, ring increases the time
it takes to compile Inko from source.

Starting with 0.19.1 Inko uses [graviola](https://github.com/ctz/graviola)
instead. Not only is it much faster and easier to compile on Inko's supported
targets, it also provides [better performance in certain
areas](https://jbp.io/graviola/). It's also actively maintained.

For users of Inko this won't be a visible change (other than that building Inko
from source will take less time), but for the maintainers it makes things
easier.

## A new operator for negating booleans

To check if a `Bool` value is `true` or `false`, the `Bool` type provided the
methods `Bool.true?` and `Bool.false?`, with the latter being most commonly used
to negate conditions:

```inko
if something_is_true.false? { do_the_thing }
```

This approach was a remnant from past versions of Inko when Inko was taking an
approach similar to Smalltalk, with conditionals (e.g. `if`) being methods
instead of expressions/dedicated syntax. Unfortunately, this approach can be
rather clunky when the condition is more than just a single short variable (such
as a chain of method calls).

This release removes the `Bool.true?` and `Bool.false?` and introduces the `!`
unary operator found in many other languages, meaning you now write the
following instead:

```inko
if !something_is_true { do_the_thing }
```

## Better support for linking large numbers of object files

To link object files, Inko's compiler invokes the appropriate linker by spawning
a sub-process and passing it the necessary command-line arguments. Depending on
the size of a project this may result in the number of arguments being greater
than supported by the linker or operating system.

To resolve this, the compiler now generates a file containing the object file
names and passes _just_ the path to this file to the linker. Such a file is
sometimes referred to as a "linker response file". This approach means that the
compiler is now able to link any number of object files.

Thanks to [r0nsha](https://github.com/r0nsha) for implementing this!

## Support for building multiple executables in a project

It's now easier for projects to build multiple executables. Instead of treating
`src/main.inko` as the only source file for an executable, running `inko build`
now compiles every file located directly in the `src` directory into an
executable. Consider this project layout for example:

```
src/
  foo/
    bar.inko
  client.inko
  server.inko
```

Running `inko build` compiles `client.inko` into a `client` executable and
`server.inko` into a `server` executable. The file `bar.inko` is _not_ compiled
into a separate executable because it isn't placed directly in the `src`
directory.

As part of this change the `--output` option is removed from the `inko build`
command as it's no longer necessary to produce meaningful names for executables.

## Better code generation for match expressions

The code generated for `match` expressions didn't handle complex `match`
expressions well, resulting in the compiler generating large and inefficient
code. Take this code for example:

```inko
match (a, b) {
  case (A, B) -> true
  case _ -> false
}
```

Assuming `a` and `b` are enums each with 100 constructors, this code would
generate 100 branches for the first value in the tuple, and then 100 branches
for the second value _for each_ first branch. In other words, the total number
of branches would be at least 100 * 100. Depending on the exact type this could
further explode by inlining their increment/decrement/drop glue methods,
potentially resulting in hundreds of thousands basic blocks/branches.

While our own compiler logic was fine with this (apart from it increasing memory
usage), LLVM doesn't like  functions with 500 000 basic blocks and would spend
up to 30 seconds compiling just a single such function.

This release includes changes to the compiler that resolves this issue,
resulting in drastically improved machine code and reduced compile times for
large `match` expressions.

## A new way of specializing generics

To specialize generic functions and types, Inko used to group types together in
buckets called "shapes", based on the layout (e.g. the size on the stack) of
these types. The idea was that this would allow for better compile times while
still offering good runtime performance. In addition, we thought it would result
in a simpler implementation compared to the traditional approach of specializing
generics over types.

Starting with Inko 0.19.1 we now specialize generics over types instead of
shapes, similar to what other statically typed languages do. This new
implementation is not only less complex, but also improves compile times by
20-30% while reducing executable sizes by 10-25%. It should also lead to
improved runtime performance, though this depends highly on the code in question
(e.g. for IO heavy code you might not notice a difference).

For more details, refer to the following:

- [Specialize over individual types instead of shapes](https://github.com/inko-lang/inko/commit/533a94f83dd791707eeb7cfa45f1ab6314bf067d)
- [Stack overflow when specializing generic type instances](https://github.com/inko-lang/inko/issues/851)
- [Undefined symbol error during linking as a result of incremental compilation](https://github.com/inko-lang/inko/issues/808)

## Changes to handling of integer overflows

The `Int` type was implemented such that overflows/underflows would trigger a
runtime panic. Unfortunately, we found that this has a non-trivial cost due to
the extra branching in generated code that this introduces.

Starting with Inko 0.19.1 the behavior is different: in debug builds an overflow
results in a panic, while in release builds it results in the value wrapping
around using two's complement. This results in more efficient code for release
builds, while still allowing you to catch overflows in debug builds.

The `Int` type still provides methods for wrapping arithmetic (e.g.
`Int.wrapping_add`) and checked arithmetic (e.g. `Int.checked_add`), so you can
still choose to deviate from this behavior where necessary.

## A more efficient StringBuffer implementation

The `StringBuffer` type is used for dynamically building `String` values at
runtime, as `String` itself is an immutable type. In past versions,
`StringBuffer` was a wrapper around an `Array[String]`, which wasn't the most
efficient implementation memory usage wise, and how the data was concatenated.

Starting with this release, `StringBuffer` is instead a wrapper around a
`ByteArray`, which makes dynamically building `String` values a little more
efficient.

Thanks to [Keithcat1](https://github.com/Keithcat1) for implementing this!

## Support for newer versions of LLVM

Past versions of Inko required the use of specific versions of LLVM. This meant
that updates to LLVM could result in Inko's compiler no longer working. Starting
with this release we now provide better support for newer versions of LLVM, as
long as the minimum LLVM version is 18.0. This means that whether you're using
LLVM 18, 19, 20 or 21, it should just work.

Do note that LLVM doesn't necessarily follow semantic versioning so it's still
possible a future LLVM version won't work based on the changes included.

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb) or star the [project on
GitHub](https://github.com/inko-lang/inko). You can also subscribe to the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

Development of Inko is self-funded, but this isn't sustainable. If you'd like to
support the development of Inko and can spare $5/month, _please_ become a
[GitHub sponsor](https://github.com/sponsors/YorickPeterse) as this allows us to
continue working on Inko full-time.
