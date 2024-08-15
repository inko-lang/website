---
{
  "title": "Inko 0.16.0 released",
  "date": "2024-08-15T14:00:00Z"
}
---

We're pleased to announce the release of Inko 0.16.0. This release includes
support for TLS sockets, automatically installing dependencies, and more.

## [Table of contents]{toc-ignore}

::: toc
:::

For the full list of changes, refer to the
[changelog](https://github.com/inko-lang/inko/blob/v0.16.0/CHANGELOG.md#0160-2024-08-14).

A special thanks to the following people for contributing changes included in
this release:

- [Tomoki Aonuma](https://github.com/uasi)

We'd like to thank the [NLnet foundation][nlnet] for sponsoring part of the work
that went into this release.

## Support for TLS sockets

::: info
Thanks to the [NLnet foundation][nlnet] for [sponsoring][nlnet-announcement] the
development of this feature.
:::

Inko 0.16.0 introduces support for TLS 1.2 and TLS 1.3 sockets using the new
[`std.net.tls`](https://docs.inko-lang.org/std/v0.16.0/module/std/net/tls/)
module, built on top of [rustls](https://github.com/rustls/rustls/) instead of
using OpenSSL. Compared to OpenSSL, rustls offers various benefits:

- It has a better history when it comes to security and code quality
- It makes cross-compilation of Inko's runtime easier, as one doesn't need to
  also compile OpenSSL for each platform.
- Using rustls and
  [rustls-platform-verifier](https://github.com/rustls/rustls-platform-verifier),
  Inko is able to verify certificates using a platform's native verification
  mechanism, something OpenSSL doesn't support.
- The rustls API is more pleasant/easier to use and makes it much more difficult
  to shoot yourself in the foot by accident.

Our initial plan was to write the TLS stack from scratch in Inko itself. We
decided against this due to the sheer amount of work required to make this
happen, along with the various language additions needed to support this ( AES
hardware intrinsics, constant-time cryptographic primitives, etc). Over time
we'll likely move towards a pure Inko TLS stack, but this isn't a priority for
the foreseeable future.

The `std.net.tls` module offers types for both TLS clients and servers. For
example, using
[`std.net.tls.Client`](https://docs.inko-lang.org/std/v0.16.0/module/std/net/tls/Client/)
we can perform a simple HTTPS 1.0 request as follows:

```inko
import std.net.ip (IpAddress)
import std.net.socket (TcpClient)
import std.net.tls (Client, ClientConfig)
import std.stdio (STDOUT)

class async Main {
  fn async main {
    let sock = TcpClient.new(ip: IpAddress.v4(1, 1, 1, 1), port: 443).or_panic(
      'failed to connect to the server',
    )

    # The configuration details (e.g. the certificates) to use for a client. You
    # should create these once and then clone the value whenever necessary.
    # Using `ClientConfig.new` means Inko will use the host platform's mechanism
    # for validating certificates. You can also use a custom certificate using
    # `ClientConfig.with_certificate`.
    let conf = ClientConfig.new

    # The return type of `Client.new` is `Option[Client]`, and will be a `Some`
    # if the server name is valid, otherwise a `None` is returned.
    let client = Client.new(sock, conf, name: 'one.one.one.one').or_panic(
      'the server name is invalid',
    )

    client
      .write_string('GET / HTTP/1.0\r\nHost: one.one.one.one\r\n\r\n')
      .or_panic('failed to write the request')

    let resp = ByteArray.new
    let stdout = STDOUT.new

    client.read_all(resp).or_panic('failed to read the response')
    stdout.print(resp.into_string)
  }
}
```

Using
[`std.net.tls.Server`](https://docs.inko-lang.org/std/v0.16.0/module/std/net/tls/Server/)
we can create a TLS server:

```inko
import std.crypto.x509 (Certificate, PrivateKey)
import std.net.ip (IpAddress)
import std.net.socket (TcpServer)
import std.net.tls (Server, ServerConfig)
import std.stdio (STDOUT)

class async Main {
  fn async main {
    # Normally you'd read the certificate and private key from a file or a
    # database, but for the sake of simplicity we're using (invalid) dummy data
    # here.
    let cert = Certificate.new(ByteArray.from_array([1, 2, 3]))
    let key = PrivateKey.new(ByteArray.from_array([4, 5, 6]))

    # This creates the configuration to use for server connections. This returns
    # a `Result` as the operation may fail, such as when the private key or
    # certificate contains invalid data.
    let conf = ServerConfig.new(cert, key).or_panic(
      'failed to create the server configuration',
    )

    # This sets up the TCP socket to use for accepting new connections.
    let server = TcpServer
      .new(ip: IpAddress.v4(0, 0, 0, 0), port: 9000)
      .or_panic('failed to start the server')

    # Now we can accept a new connection, wrapping it in a `Server` instance.
    let con = server.accept.map(fn (sock) { Server.new(sock, conf) }).or_panic(
      'failed to accept the new connection',
    )

    let bytes = ByteArray.new
    let stdout = STDOUT.new

    con.read(into: bytes, size: 32).or_panic('failed to read the data')
    stdout.print(bytes.into_string)
  }
}
```

For more details, refer to [issue
#329](https://github.com/inko-lang/inko/issues/329) and commit
[a9c7bd7](https://github.com/inko-lang/inko/commit/a9c7bd726c34682ce7c12afdac4d90879c39d778).

## Support for encoding and decoding base64 data

The standard library provides the new module
[`std.base64`](https://docs.inko-lang.org/std/v0.16.0/module/std/base64/), which
in turn provides types for encoding and decoding data as/from base64.

Encoding is done using
[`std.base64.Encoder`](https://docs.inko-lang.org/std/v0.16.0/module/std/base64/Encoder/):

```inko
import std.base64 (Encoder)
import std.stdio (STDOUT)

class async Main {
  fn async main {
    let base64 = ByteArray.new
    let stdout = STDOUT.new

    Encoder.new.encode('hello world'.to_byte_array, into: base64)
    stdout.print(base64.to_string) # => 'aGVsbG8gd29ybGQ='
  }
}
```

Decoding is done using
[`std.base64.Decoder`](https://docs.inko-lang.org/std/v0.16.0/module/std/base64/Decoder/):

```inko
import std.base64 (Decoder)
import std.stdio (STDOUT)

class async Main {
  fn async main {
    let plain = ByteArray.new
    let stdout = STDOUT.new

    Decoder.new.decode('aGVsbG8gd29ybGQ='.to_byte_array, into: plain)
    stdout.print(plain.to_string) # => 'hello world'
  }
}
```

For simple cases you can also use the methods
[`std.base64.encode`](https://docs.inko-lang.org/std/v0.16.0/module/std/base64/encode/)
and
[`std.base64.decode`](https://docs.inko-lang.org/std/v0.16.0/module/std/base64/decode/).

For more details, refer to commit
[09ad36e](https://github.com/inko-lang/inko/commit/09ad36e6c37f231b241cb6a535fad872a72c6089).

## Automatic installation of build dependencies

Thanks to Tomoki Aonuma, Inko now automatically installs dependencies when
running commands such as `inko build`, `inko test` and `inko doc`, removing the
need for manually running `inko pkg sync`:

```
$ ls dep
ls: cannot access 'dep': No such file or directory

$ inko build
Downloading https://github.com/yorickpeterse/inko-wobsite v0.18.0
Downloading https://github.com/yorickpeterse/inko-builder v0.13.0
Downloading https://github.com/yorickpeterse/inko-markdown v0.20.1
Downloading https://github.com/yorickpeterse/inko-syntax v0.9.0

$ ls dep
5a0dc78739a032c3b9ba351cdc84abbeb5472ef757699f6e7acb077b9e412071  6eca2ee9336610b3b5fafa7675508b7c76aae0d7748d089ad2e6ec68d017947b  hash
5e9313d54ba89b1b633b439b5900aadcbecc41bd97aabd10bee95ac8a07a8ae5  a11b9ff96cc9ab66a68aa775c66b7e0436a6ed4416afa47fdf1559de232e3b51
```

You can of course still run `inko pkg sync` manually in case you want to
install the dependencies ahead of time.

For more details, refer to [pull request
#742](https://github.com/inko-lang/inko/pull/742) and commit
[3047976](https://github.com/inko-lang/inko/commit/30479762979249ccc68ce937555c0902e3c33d39).

## Requiring a minimum Inko version to build a project

Also thanks to Tomoki Aonuma, you can now specify a minimum version of Inko
that's required to build a project by running `inko pkg add inko X.Y.Z` where
`X.Y.Z` is the version. For example, to require 0.16.0 or newer you'd run the
following in your project:

```
inko pkg add inko 0.16.0
```

The required version is stored in the package manifest (`inko.pkg`), so make
sure to track this file in Git if not done so already.

For more details, refer to [pull request
#739](https://github.com/inko-lang/inko/pull/739) and commit
[bc06c3e](https://github.com/inko-lang/inko/commit/bc06c3e06847e29645c4949081168845202b2a74).

## Less data is cloned when downloading dependencies

Inko dependencies are Git repositories hosted on platform such as
[GitHub](https://github.com/) and [GitLab](https://gitlab.com/). These packages
are downloaded using `git clone`, after which the necessary files are copied
into a project's `dep/` directory.

Thanks to Tomoki Aonuma, we now clone only the data we need to install a package
into a project, instead of cloning the entire repository. This should speed up
the download process and require less disk space when cloning large
repositories.

For more details, refer to [pull request
#737](https://github.com/inko-lang/inko/pull/737) and commit
[ab90f67](https://github.com/inko-lang/inko/commit/ab90f67c99fcbef66ddac13a5e5d694414cebfd9).

## Generics now support C types of different sizes

Inko used to not allow C types such as `Int16` and `Float32` to be passed to
generic type parameters, thus disallowing types such as `Array[Float32]`.
Starting with 0.16.0 this is supported and allowed, and the `Array` type is
changed to use the correct size for its memory buffer based on the data it
stores, instead of using a fixed size of 8 bytes.

In isolation this isn't terribly interesting, in particular since we still
disallow C structures in generic contexts, but it paves the way for stack
allocating types of different sizes (instead of everything being heap allocated)
and being able to use them in generic contexts, something we aim to implement in
the future.

For more details, refer to commit
[f156a36](https://github.com/inko-lang/inko/commit/f156a367f015bb4e0292058719f551139bda6d0c).

## LLVM 17 or newer is required

Starting with 0.16.0, LLVM 17 or newer is required to build the compiler. Newer
versions might also work depending on the changes introduced by LLVM, but we
recommend using LLVM 17 whenever possible.

For more details, refer to commit
[f3d5cd5](https://github.com/inko-lang/inko/commit/f3d5cd5b5948b4d40ccb30ab10fc9f2cc200af19).

## Rust 1.78 or newer is required

The version requirement of Rust has been increased from 1.70.0 to 1.78.0.
Building Inko using an older version of Rust _might_ work but isn't supported.

For more details, refer to commit
[63086b2](https://github.com/inko-lang/inko/commit/63086b26d2008be2b9053994b415c7c56ce06208).

## Building the compiler is easier on macOS and FreeBSD

Starting with 0.16.0 it's easier to build Inko's compiler on macOS and FreeBSD,
as you no longer need to set the `LIBRARY_PATH` and `PATH` variables to ensure
Rust is able to find the necessary LLVM libraries and executables.

For more details, refer to [this llvm-sys merge
request](https://gitlab.com/taricorp/llvm-sys.rs/-/merge_requests/45) and commit
[f5aa237](https://github.com/inko-lang/inko/commit/f5aa237531ccca23c50cc4ce08446ba51f54bbcd).

## Removal of deprecated syntax

In the release post for [0.15.0](/news/inko-0-15-0-released/) we announced the
deprecation of the class literal and trailing closure syntax, and support for
this syntax is removed in 0.16.0. If you're still using 0.14.0 or older, first
upgrade to 0.15.0 and run `inko fmt` to update the syntax, then upgrade to
0.16.0.

For more details, refer to commit
[79c0220](https://github.com/inko-lang/inko/commit/79c02206052c121adc435cff5e3df753ceb55b80).

## Performance improvements

The following performance improvements are included in this release:

- [Use `llvm.abs` for `Int.absolute`](https://github.com/inko-lang/inko/commit/00a0d186c7d0ab102e92a645d9d65a4f71f01b22)
- [Optimize pkg sync by cloning a single ref](https://github.com/inko-lang/inko/commit/ab90f67c99fcbef66ddac13a5e5d694414cebfd9)
- [Optimize `std.endian.big` and `std.endian.little`](https://github.com/inko-lang/inko/commit/9423067572a294ab86fa21437635e7a9245680a1)
- [Optimize `String.starts_with`/`ends_with`](https://github.com/inko-lang/inko/commit/9dc7fd4d58fa22c8023559b373c2870ce4356164)
- [Improve performance of `String.==`](https://github.com/inko-lang/inko/commit/8bae81628bbf48313ab5f1fda50a13a585911ad6)
- [Only increase read sizes when beneficial](https://github.com/inko-lang/inko/commit/03841622f635d6129ce6f39edc8144364fc6eb11)

## Bug fixes

The following bug fixes are included in this release:

- [Fix assigning types with ownership to placeholders](https://github.com/inko-lang/inko/commit/119e77bc25edc6962c5267a03395a7f54aa1ec94)
- [Fix trailing compression in `Ipv6Address.to_string`](https://github.com/inko-lang/inko/commit/d023bfebaef1b5dfb283ddd82313a734ae969fef)
- [Fix referring to fields storing pointers](https://github.com/inko-lang/inko/commit/e72c6a259ce96a115a4971ae93b286aaefb656f9)
- [Fix underflows when formatting certain call chains](https://github.com/inko-lang/inko/commit/b3cc7cfc629289d93bb5bcb3c8866997f763b156)
- [Fix `BufferedReader.fill_buffer`](https://github.com/inko-lang/inko/commit/2c3cc1fc4cf0cb21fc1bc10edf250addfd8c9b1d)

## [Following and supporting Inko]{toc-ignore}

If Inko sounds like an interesting language, consider joining the [Discord
server](https://discord.gg/seeURxHxCb). You can also follow along on the
[/r/inko subreddit](https://www.reddit.com/r/inko/).

If you'd like to support the continued development of Inko, please consider
donating using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse) as
this allows us to continue working on Inko full-time.

[nlnet]: https://nlnet.nl/
[nlnet-announcement]: /news/inko-0-12-0-released/#inko-receives-funding-from-nlnet
