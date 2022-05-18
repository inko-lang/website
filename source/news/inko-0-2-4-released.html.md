---
author: Yorick Peterse
title: Inko 0.2.4 released
date: 2018-09-09 19:00:00 UTC
description: Inko 0.2.4 released
---
<!-- vale off -->

Inko 0.2.4 has been released.

<!-- READ MORE -->

This release contains quite a few drastic changes compared to previous releases.
Most notable, panics have been overhauled, cleaning up resources (such as
closing file handles) has been made easier, and various bugs have been resolved.

For Inko 0.3.0 we plan to start working on features such as:

1. [Networking support][networking]
1. [A Foreign Function Interface][ffi]
1. [Parsing and formatting of Time objects][parse-format-time]

FFI support might be delayed to a future release, as this is likely going to
take a lot of work to implement.

For more information, see the [issues scheduled for the 0.3.0 milestone][0.3.0].

## Noteworthy changes in 0.2.4
{:.no_toc}

* TOC
{:toc}

The full list of changes can be found in the [CHANGELOG][changelog].

### More consistent syntax when passing blocks as the last argument

When passing arguments using parentheses, Inko now allows you to place a block
outside of these parentheses, causing it to be treated as the last argument:

```inko
import std::stdio::stdout

[10, 20, 30].each() do (number) {
  stdout.print(number)
}
```

This would be parsed the same way as the following code:

```inko
import std::stdio::stdout

[10, 20, 30].each(do (number) {
  stdout.print(number)
})
```

Previously, when passing a block as the last argument the recommended style was
to leave out the parentheses, meaning you'd write the following:


```inko
import std::stdio::stdout

[10, 20, 30].each do (number) {
  stdout.print(number)
}
```

However, this is inconsistent, and can at times make the code harder to read.
This new syntax allows for a more consistent syntax, without having to place the
block inside parentheses, which can look unappealing. Inko's own unit tests
benefited quite a bit from these changes, allowing us to turn this:

```inko
test.group 'std::fs::dir.list', do (g) {
  g.test 'Listing the contents of an empty directory', {
    with_temp_dir [], do (path) {
      let contents = try! dir.list(path)

      assert.equal(contents, [])
    }
  }
}
```

Into this:

```inko
test.group('std::fs::dir.list') do (g) {
  g.test('Listing the contents of an empty directory') {
    with_temp_dir([]) do (path) {
      let contents = try! dir.list(path)

      assert.equal(contents, [])
    }
  }
}
```

### Sending unknown messages to Nil works again

Inko allows you to send any message to `Nil` and another `Nil` will be returned.
Unfortunately, recent refactoring of the compiler broke support for this. Inko
0.2.4 resolves these problems, allowing for code such as `Nil.does_not_exist` to
compile again.

### Cleaning up resources using deferred blocks

Every language offers a way to clean up resources, such as closing file handles,
or removing temporary files. Many dynamic languages, such as Ruby, use
[finalizers][finalizers] for this. Finalizers are difficult to implement right,
and are difficult to use. There's often no guarantee when they run, or if they run
at all. If finalizers are executed concurrently with a program race conditions
can occur, but if they don't they may slow down the program. In short, we felt
it was best to avoid them at all costs.

Unfortunately, Inko didn't really provide a viable alternative. Manually closing
resources would work, except in the event of a panic such operations may not be
executed.

Inko 0.2.4 introduces the concept of "deferred blocks". The idea is taken from
[Go][golang], and is quite simple. A deferred block is simply a block of code
that is executed when we return from the scope that defined it. Such blocks are
always executed, even when throwing, an error or when triggering a panic. This
allows you to clean up resources, even in the event of a panic.

Using deferred blocks can be done using `std::process.defer`:

```inko
import std::fs::file
import std::process

let file = try! ::file.write_only('test.txt')

process.defer {
  file.close
}

try! file.write_string('hello')
```

Here `file.close` will always be executed, ensuring the file handle is closed.

Using `std::process.defer` directly can lead to rather verbose code, so we are
considering introducing more high-level abstractions on top in the future. There
is no exact implementation yet, but the idea is to offer something similar to
Python's ["with" statement][pep343]:

```inko
import std::fs::file

try! { file.write_only('test.txt') }.with do (file) {
  try! file.write_string('hello')
}
```

Here the idea is that once the block passed to `with` returns (or throws, or
panics), the `file` object is closed before we continue.

Note that at this point this is just an idea, and the final implementation could
differ significantly.

### Responding to panics using panic handlers

Prior to Inko 0.2.4, a panic would terminate the entire program. Starting with
0.2.4, this is no longer always the case. Processes can now register a panic
handler, which is a block that will be executed in the event of a panic. Once
the handler finishes, the _process_ is terminated. There is no way to recover
from a panic, as panics are usually the result of a serious bug, and usually the
only sane response is to restart the process. Since a process panicked, it may
not be able to restart itself (or even know how to do so), and so we terminate
it.

If a process does not define its own panic handler, the default global panic
handler will be executed. This handler prints a stack trace, then terminates the
_entire program_.

This particular setup means that by default a panic is very obvious, because our
program crashes. At the same time, we're able to scope this to individual
processes by telling them how to react to a panic.

Registering a process specific panic handler is done using
`std::process.panicking`:

```inko
import std::process
import std::stdio::stderr

process.panicking {
  stderr.print('oops, we ran into a panic!')
}
```

The global handler can be overwritten using `std::vm.panicking`:

```inko
import std::vm
import std::stdio::stderr

vm.panicking {
  stderr.print('oops, we ran into a panic!')
}
```

Note that you can not restore the global panic handler after you have redefined
it. Also keep in mind that if you overwrite the global panic handler, Inko will
_not_ terminate the program for you, as this is done by the default global
handler. This means that if you still want to terminate the program, you have to
do so manually using `std::vm.exit`:

```inko
import std::vm
import std::stdio::stderr

vm.panicking {
  stderr.print('oops, we ran into a panic!')
  vm.exit(1)
}
```

### Obtaining environment data using std::env

Environment data, such as environment variables and command-line arguments, can
now be accessed using the module `std::env`. For example, we can read
environment variables like so:

```inko
import std::env

env['HOME'] # => '/home/alice'
```

We can also obtain directory information, such as the home directory and the
temporary directory:

```inko
import std::env

env.home_directory      # => '/home/alice'
env.temporary_directory # => '/tmp'
```

### std::io::Close.close can no longer throw

A while back the `std::io` module was changed quite a bit, and
`std::io::Close.close` was changed to allow it to throw. This release reverts
this. Whether or not closing a resource fails or not doesn't really matter, as a
program can just continue running. Requiring the use of `try` or `try!` when
using `Close.close` thus led to unnecessarily verbose code.

### std::test now uses panics, instead of throwing values

With the changes to panics, and the introduction of panic handlers, `std::test`
has been changed to panic whenever an assertion is not met, instead of throwing
an error. This means you can now write `assert.equal(a, b)` instead of
`try assert.equal(a, b)`, simplifying the process of writing unit tests.

You can now also test for panics using `std::assert.panic` and
`std::assert.no_panic`.

### Memory usage has been reduced

The memory necessary to start a process has been reduced from at least 944 bytes
to at least 832 bytes, a reduction of 112 bytes. Note that we say _at least_,
because the moment a process allocates memory it will request a 32KB block of
memory.

The exact amount of memory necessary to _just_ spawn a process is probably a bit
higher, as the above number of bytes is the type size of the `Process` structure
in the virtual machine.

### Prefetching is now supported on Rust stable

In Inko 0.2.0 we introduced support for building the virtual machine using
stable Rust. However, support for [prefetching][prefetching] was only available
when using a nightly build of Rust.

Starting with Inko 0.2.4, prefetching support is now available on stable Rust.
This means you no longer need a nightly build of Rust to get the best
performance.

### The implicit "self" argument has been removed

Prior to version 0.2.4, the receiver of a method or block was passed to the
implicit first argument, called "self". This made it hard for the VM to store
and later execute blocks, as it wouldn't know what object to pass to this
argument.

As of 0.2.4, the use of this implicit argument has been removed entirely.
Instead, blocks now explicitly store their receiver, and using the `self`
keyword results in that receiver being retrieved.

These changes simplify the compiler, allow the VM to schedule blocks more
easily, and ensure that `self` doesn't show up in the list of arguments of a
block when using `std::mirror::BlockMirror.argument_names`.

[changelog]: https://gitlab.com/inko-lang/inko/blob/ae209a0dd19d4ad2995d5dc4e5cdbb1cc59e964d/CHANGELOG.md#024-september-08-2018
[finalizers]: https://en.wikipedia.org/wiki/Finalizer
[golang]: https://golang.org/
[pep343]: https://www.python.org/dev/peps/pep-0343/
[prefetching]: https://inko-lang.org/manual/virtual-machine/memory-management/#header-prefetching
[networking]: https://gitlab.com/inko-lang/inko/issues/112
[ffi]: https://gitlab.com/inko-lang/inko/issues/113
[parse-format-time]: https://gitlab.com/inko-lang/inko/issues/96
[0.3.0]: https://gitlab.com/inko-lang/inko/issues?scope=all&utf8=%E2%9C%93&state=opened&milestone_title=0.3.0
