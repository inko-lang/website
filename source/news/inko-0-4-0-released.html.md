---
author: Yorick Peterse
title: Inko 0.4.0 released
date: "2019-05-10 22:10:13 UTC"
description: Inko 0.4.0 has been released
---
<!-- vale off -->

Inko 0.4.0 has been released, with features such as: a new scheduler, support
for non-blocking sockets, and a simplified API for sending messages to
processes.

<!-- READ MORE -->

## Noteworthy changes in 0.4.0
{:.no_toc}

* TOC
{:toc}

The full list of changes can be found in the [CHANGELOG][changelog].

## New scheduler implementation

For 0.4.0 we rewrote the process scheduler from the ground up. The old scheduler
was written over two years ago, and was not built with today's requirements in
mind. Internally it made heavy use of explicit locking, which made it
inefficient.

The new scheduler's code is easier to understand, more efficient, and should be
easier to extend in the future if necessary. This new scheduler also made it
possible to add support for non-blocking network IO, which is discussed in
greater detail below.

The old scheduler used a separate thread to reschedule processes whenever they
received a message. The data structure used for storing suspended processes was
a list that was scanned linearly. This could result in processes taking a long
time to be rescheduled, if a large number of processes were suspended. In the
new setup, a process sending a message to a suspended process will try to
reschedule it right away, using atomic operations instead of explicit locking.

A separate thread is still used for processes suspended with a timeout. The
structures used by this thread are optimised in such a way that the time to
reschedule a process stays short, and no explicit locking is used when adding
new entries to these data structures.

A side-effect of these changes is that processes now require an extra word of
memory per process. The extra memory is used to more efficiently suspend and
resume processes concurrently, removing the need for explicit locking.

More information about these changes can be found in commit
[3e5882][new-scheduler].

## Support for non-blocking sockets

Inko now supports non-blocking TCP, UDP, and Unix domain sockets. This is
provided using three modules:

1. `std::net::socket`: provides TCP and UDP sockets.
1. `std::net::unix`: provides Unix domain sockets.
1. `std::net::ip`: provides types and methods for parsing and building IPv4 and
   IPv6 addresses.

The socket libraries provide various high-level socket types, as well as
low-level types. For example, a TCP server can be created using
`std::net::socket::TcpListener`, which wraps a `std::net::socket::Socket`. The
`Socket` type in turn can be used when more control over the socket is
necessary.

For example, to create a simple TCP server that just writes back the message
sent, you would write the following:

```inko
import std::net::socket::TcpListener

let listener = try! TcpListener.new(ip: '0.0.0.0', port: 40_000)

{
  let client = try! listener.accept
  let message = try! client.read_string(32)

  try! client.write_string(message)
  try! client.shutdown

  client.close
}.loop
```

This server would read up to 32 bytes sent by a client, then write the message
back to it.

Sockets can be sent across processes, allowing for different processes to listen
on the same socket. This allows for writing of efficient socket servers, instead
of the server being limited by how fast a single process can accept new
connections.

Checking if certain sockets are ready for reading and/or writing (using
`select(2)` for example) is not possible yet. We aim to add support for such an
API in a future release. More information about this can be found in issue
["Checking if sockets are ready for reading, writing, or both"][issue-163].

## Reduced Immix block sizes

In 0.4.0 we reduced the size of every Immix block from 32KB to 8KB. This allows
for spawning of more processes, using less memory.

## Rust 2018 is now required

The VM now requires the 2018 edition of Rust to build, which is available
starting with Rust 1.31.

## Processes no longer use PIDs

Before 0.4.0, Inko assigned every process a unique process identifier (PID).
When sending a message you would use a PID to determine what process to send the
data to. Generating PIDs could be extensive when all available PID were used at
least once. Explicit locking was also required, as the data structures used were
not concurrent data structures.

In 0.4.0 we removed the use of PIDs altogether. Process communication is now
done using the `Process` type, and `std::process.current` will return an
instance of this type, instead of returning an `Integer`. This makes spawning
processes faster, and leads to a more pleasant to use process API.

In short, instead of this:

```inko
import std::process
import std::stdio::stdout

let pid = process.spawn {
  let message = process.receive as String

  stdout.print(message)
}

process.send(pid: pid, message: 'ping')
```

You now write this:

```inko
import std::process
import std::stdio::stdout

let child = process.spawn {
  let message = process.receive as String

  stdout.print(message)
}

child.send('ping')
```

## std::process.channel has been removed

The method `std::process.channel` has been removed. The API in question was not
pleasant to use, and provided limited use. We intend to reintroduce a different
type-safe process communication API in a future release.

## Faster bytecode parsing

The time the VM spends parsing bytecode files has been reduced by reading data
in chunks, instead of reading bytecode one byte at a time. In some cases this
can lead to bytecode being parsed ten times faster.

More information about this change can be found in commit [d80c4c][bytecode].

## std::time has been reorganised

The module `std::time` has been broken up into two modules:

1. `std::time`
1. `std::time::duration`

The `MonotonicTime` type has been renamed to `Instant`.

More information about these changes can be found in commit [7f0cb4][std-time].

[changelog]: https://github.com/inko-lang/inko/blob/v0.4.0/CHANGELOG.md#040---may-11-2019
[new-scheduler]: https://github.com/inko-lang/inko/commit/3e5882be8ce36b594c9012f236d14207fc8983cf
[bytecode]: https://github.com/inko-lang/inko/commit/d80c4c30f61e6c2d89cfde5079deb41f9035c681
[std-time]: https://github.com/inko-lang/inko/commit/7f0cb46bcd3769045934d55c28ea66d326a05c50
[issue-163]: https://github.com/inko-lang/inko/issues/233
