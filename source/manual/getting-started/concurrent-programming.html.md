---
title: Concurrent programming
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Inko allows you to perform work concurrently by using "lightweight processes".
Lightweight processes (more commonly known as "green threads") are isolated
tasks, scheduled by the virtual machine. Processes can never read each other's
memory, instead they communicate by sending messages. These messages can be any
object, and they are deep copied when sent. A process can continue running while
receiving many messages, without impacting performance.

Processes using isolated memory means never having to worry about data races.
Mutexes (or other types of locking mechanisms) are also no longer necessary, as
you can instead just use a process to synchronise access to a resource.

Inko uses preemptive multitasking for processes. This means that each process
runs for a certain period of time on an OS thread, after which it is suspended
and another process is allowed to run. This repeats itself until the program
terminates.  Because of the use of preemptive multitasking, a single process is
unable to block an OS thread from performing any other work indefinitely.

## Sending messages

To get started with processes, you must first import the `std::process` module
into your module:

```inko
import std::process
```

This module provides a variety of methods we can use, but let's start simple:
we'll start a process, then send it a message. The started process in turn will
receive a message, then just terminate. First, let's start the new process:

```inko
import std::process

let pid = process.spawn {

}
```

By sending the message `spawn` to the `process` module we can start a new
process. The argument we provide is a lambda that will be executed in the newly
started process. The return value is the PID of the process, which we can later
use to send messages to it. Each process is given a unique PID, although it is
possible for a PID to be reused once the process it belonged to has been
terminated.

Now let's change our code so that our process waits for a message to arrive:

```inko
import std::process

let pid = process.spawn {
  process.receive
}
```

Here we use `process.receive` to wait for a new message. Once received, we just
discard it.

When a process tries to receive a message, one of two things can happen:

1. If there is no message, the process will suspend itself until a message
   arrives.
1. If there is a message, simply return it.

So far we haven't sent a message yet to our process, so it will suspend itself
and wait for us to send one. Let's send it a message:

```inko
import std::process

let pid = process.spawn {
  process.receive
}

process.send(pid: pid, message: 'ping')
```

Using `process.send` allows us to send a message to a process. When using the
`send` message, we must provide two arguments:

1. The PID of the process to send the message to.
1. The message to send.

In the above example we use explicit keyword arguments for `process.send`, but
we could have left them out as well. It is considered a best practise to use
explicit keyword arguments when supplying more than one argument, as this makes
it easier to understand the meaning of the arguments.

## Copying messages

When a message is sent, it is _deep copied_. This means that the sender and
receiver will both use a different copy of the data sent. Certain types however
are optimised for copying. For example, objects of type `Integer` are not heap
allocated, removing the need for copying. Objects of type `String` use reference
counting internally, making it cheap to send a `String` from one process to
another.

Despite these optimisations, it is best to avoid sending really large objects to
different processes. Instead, we recommend that a single process owns the data
and sends out some kind of reference (e.g. an ID of sorts).

Having said all that, copying a message is typically cheaper than using a lock
of sorts to allow concurrent access to shared memory. Furthermore, Inko tries
really hard to reuse memory as best as it can. As a result, the overhead of
copying typically won't be something you should worry about.

## Waiting for a response

So far our program doesn't do a whole lot: we start a process, send it a
message, then terminate. Let's change our program so that the started process
sends a response back, and our main process waits for it to be received:

```inko
import std::process

let pid = process.spawn {
  process.receive

  process.send(pid: 0, message: 'pong')
}

process.send(pid: pid, message: 'ping')

process.receive
```

Our started process now sends the message "pong" to the process with PID 0. But
which process is that? Well, the process with PID 0 is simply the process that
is started first. In our above example this is the same process that runs
`process.spawn`, then waits for the "pong" message.

While our program works, there's a bit of a problem: we always send our response
to process 0, instead of the process that sent us the message. Let's change
this!

```inko
import std::process

let pid = process.spawn {
  let pid = process.receive as Integer

  process.send(pid: pid, message: 'pong')
}

process.send(pid: pid, message: process.current)

process.receive
```

This is quite a bit of a jump from the previous example, so let's discuss it
step by step. We start our process as usual, which then runs the following:

```inko
let pid = process.receive as Integer
```

This line of code does two things:

1. We wait for a message to arrive.
2. We inform the compiler that our message is of type `Integer`.

Step one is nothing new, but step two needs some explaining. When we use
`process.receive`, the compiler is does not know what the type of the received
message is. This is because a process can receive messages from many other
processes, possibly using different types. As a result, the return type of
`process.receive` is `Dynamic`. To further explain, let's look at the next line:

```inko
process.send(pid: pid, message: 'pong')
```

Here we pass the `pid` variable as the PID to send the message to. This variable
contains the PID that was sent to us. The `pid:` argument of `process.send`
takes an `Integer`, but `process.receive` returns a `Dynamic`. We can't pass a
`Dynamic` to an `Integer`, so we have to cast it. We do this by using the `as`
keyword, which is used like so:

```inko
expression as TypeToCastTo
```

Finally, we have the following line:

```inko
process.send(pid: pid, message: process.current)
```

Here we use `process.current` to return the PID of the currently running
process, which happens to be process 0 in this case. We then use this value as
the message to send, allowing the receiving process to send a response back to
us.

## Type safe process communication

Using dynamic types for messages can get tricky rather quickly, especially once
we start sending more complex types of messages such as custom objects. Let's
say we want to send both the PID of the sender, a message, and have the receiver
_only_ send back "pong" if the input message was "ping". In this case we would
end up with something like this:

```inko
import std::process

object Message {
  def init(sender: Integer, message: String) {
    let @sender = sender
    let @message = message
  }

  def sender -> Integer {
    @sender
  }

  def message -> String {
    @message
  }
}

let pid = process.spawn {
  let message = process.receive as Message

  message.message == 'ping'
    .if_true {
      process.send(pid: message.sender, message: 'pong')
    }
}

let message = Message.new(process.current, 'ping')

process.send(pid: pid, message: message)

process.receive
```

That's quite a lot! We define a custom `Message` object that we will use for
storing the PID, and our message (a `String`). We then create a new instance of
our `Message` object, and send this to the receiving process.

While this program will work, it is not type safe. For example, nothing is
stopping us from changing our code to do the following:

```inko
import std::process

object Message {
  def init(sender: Integer, message: String) {
    let @sender = sender
    let @message = message
  }

  def sender -> Integer {
    @sender
  }

  def message -> String {
    @message
  }
}

let pid = process.spawn {
  let message = process.receive as Message

  message.message == 'ping'
    .if_true {
      process.send(pid: message.sender, message: 'pong')
    }
}

process.send(pid: pid, message: 'oh no, this will break!')
```

If we try to run this, we'll be presented with a rather scary looking runtime
error:

```
Stack trace (the most recent call comes last):
  0: "/tmp/test.inko", line 21, in "<block>"
Process 1 panicked: ObjectValue::as_block() called on a non block object
```

Runtime errors are currently not yet very helpful, but what this means is that
we tried to send `message` (in the receiver) to something that did not respond
to it. This is because we are sending a message of type `String`, and not of
type `Message`.

Fortunately, we can fix this! To do so, we need to use a different method:
`process.channel`. This method will start a process for us, but only allow us to
send it messages of a given type, which we provide when using `process.channel`.
Let's change our example to use this new approach:

```inko
import std::process

object Message {
  def init(sender: Integer, message: String) {
    let @sender = sender
    let @message = message
  }

  def sender -> Integer {
    @sender
  }

  def message -> String {
    @message
  }
}

let sender = process.channel!(Message) lambda (receiver) {
  let message = receiver.receive

  message.message == 'ping'
    .if_true {
      process.send(pid: message.sender, message: 'pong')
    }
}

let message = Message.new(process.current, 'ping')

sender.send(message)

process.receive
```

Let's go through this step by step. First we have the following:

```inko
let sender = process.channel!(Message) lambda (receiver) {
  # ...
}
```

The `process.channel` method is quite different from `process.spawn`. Instead of
just taking a block and executing it, it requires us to provide:

1. The type of the message that we will be sending, as a type argument. This is
   done using `process.channel!(Message)`.
1. A lambda that takes a single argument called a "receiver".

A "receiver" is an object of type `std::process::Receiver`, and is aware of the
type of message it will be receiving.

When using `process.channel`, the return type is not an `Integer` but a
`std::process::Sender`. This is an object that knows the PID of the process to
send a message to, and the type of the messages it will be sending.

To make use of these objects, we use `sender.send` and `receiver.receive` in the
above example, instead of `process.send` and `process.receive`. Because both the
sender and receiver are aware of the message types, we no longer have to cast
anything when receiving a message. This API also makes sending messages type
safe. Let's say we change our program to the following:

```inko
import std::process

object Message {
  def init(sender: Integer, message: String) {
    let @sender = sender
    let @message = message
  }

  def sender -> Integer {
    @sender
  }

  def message -> String {
    @message
  }
}

let sender = process.channel!(Message) lambda (receiver) {
  let message = receiver.receive

  message.message == 'ping'
    .if_true {
      process.send(pid: message.sender, message: 'pong')
    }
}

sender.send('this will not work!')

process.receive
```

If we try to run this, we will be presented with the following compiler error:

```
ERROR: Expected a value of type "Message" instead of "String"
  --> /tmp/test.inko on line 27, column 13
    |
 27 | sender.send('this will not work!')
    |             ^
```

The same is the case if we try to use our received message in an incompatible
way:

```inko
import std::process

object Message {
  def init(sender: Integer, message: String) {
    let @sender = sender
    let @message = message
  }

  def sender -> Integer {
    @sender
  }

  def message -> String {
    @message
  }
}

let sender = process.channel!(Message) lambda (receiver) {
  let message = receiver.receive

  message.example == 'ping'
    .if_true {
      process.send(pid: message.sender, message: 'pong')
    }
}

let message = Message.new(process.current, 'ping')

sender.send(message)

process.receive
```

This will result in the following compiler error:

```
ERROR: The type "Message" does not respond to the message "example"
  --> /tmp/test.inko on line 21, column 11
    |
 21 |   message.example == 'ping'
    |           ^
```

In both cases the type safe API provided by `process.channel` protects us from
sending the wrong kind of data to a process, and ensures the receiver is aware
of the message type, thereby removing the need for casting it to the desired
type.

## Timeouts

Sometimes we may want to only wait for a certain period of time when receiving a
message. We can do so by providing a timeout to `process.receive`:

```inko
import std::process

process.receive(1_000)
```

When running this, our program will wait for 1000 milliseconds (= 1 second) for
a message to arrive. If no message is received, `Nil` is returned and our
program will continue.

## Conditional receives

Sometimes a process has to receive messages of radically different types. In
this case one can use `process.receive_if` to _only_ receive a message if it
meets our requirements. For example, we can use this to only receive messages of
type `String`:

```inko
import std::process
import std::reflection

let pid = process.spawn {
  process.receive_if do (message) {
    reflection.kind_of?(message, String)
  }
}

process.send(pid: pid, 'ping')
```

Here we use `reflection.kind_of?` to check if `message` is of type `String`. If
a message does not meet our criteria, _it is dropped_.

Because `process.receive_if` returns a value of type `Dynamic`, explicit type
casts may be required depending on how you act upon the returned value.

## Blocking operations

Sometimes a process needs to perform a task that will block the OS thread it is
running on. We can use the method `process.blocking` for this:

```inko
import std::process

process.blocking {
  # blocking operation here.
}
```

When we use `process.blocking`, the current process is moved to a separate
thread pool dedicated to slow or blocking processes. This allows us to perform
our blocking operation (in the provided block), while still allowing other
processes to run without getting blocked as well.

Typically you won't have to use `process.blocking` as the various Inko APIs will
take care of this for you. For example, various file system operations use
`process.blocking` to move blocking operations to the separate thread pool.

## Process monitoring

If you have worked with Erlang or Elixir before, you may wonder if there is a
way to monitor a process. Currently there isn't, and it's likely this will not
be added. Inko's error handling model prevents unexpected runtime errors from
occurring, removing the need for process monitoring. Panics in turn terminate
the entire program by default, and are not meant to be monitored from another
Inko process, as panics are the result of software bugs, and software bugs
should not be ignored.

If you want one process to act upon another process terminating, simply have the
process send a message upon termination. You can do so by registering a panic
handler in the process:

```inko
import std::process

let child = process.spawn {
  let parent = process.receive as Integer

  process.panicking do (error) {
    process.send(pid: parent, message: error)
  }
}

process.send(pid: child, message: process.current)
```

You can also use `process.status` to receive the status of a process:

```inko
import std::process

process.status(process.current) # => 1, meaning it is running
```

Keep in mind that if a process has been terminated, it's PID _might_ be reused
in the future. This means that the value returned by `process.status` is not
guaranteed to be 100% accurate, although it will take quite a while before a PID
is reused.
