---
title: Inko Programming Language
created_at: 2018-07-09
description: >
  Inko is a general-purpose, statically-typed, and easy to use programming
  language.
---

## <i class="icon-umbrella" /> Safe

Inko is a statically-typed language, and has a unique twist on error handling.
`NULL` doesn't exist in Inko, instead it uses the `Option` type for optional
data. Thanks to its memory management strategy, memory errors such as
use-after-free errors are impossible. Global mutable state doesn't exist either.
Thanks to these and other features that Inko has to offer, many bugs found in
other languages are impossible in Inko.

## <i class="icon-recycle" /> Automatic and deterministic memory management

Inko offers automatic and deterministic memory management, without the use of a
garbage collector. Instead, it uses single ownership and a form of reference
counting based on the paper ["Ownership You Can Count
On"](https://researcher.watson.ibm.com/researcher/files/us-bacon/Dingle07Ownership.pdf).
Unlike traditional reference counting, reference counts are only used when
creating references; not when creating or moving owned values. Many reference
count changes can also be optimised away, reducing the overhead of creating and
dropping references.

Unlike Rust, Inko allows you to create references to owned values and then move
those owned values, as long as they aren't dropped. If you drop a value while
references still exist, and the compiler isn't able to detect this, you'll get a
runtime panic instead. Crucially, the panic occurs when dropping the owned
value, not when dereferencing a reference some time later. This makes it easier
to debug such (rare) cases.

The allocator is a fast thread-local bump allocator based on the
[Immix](https://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf)
allocator. Fragmentation is handled by incrementally scanning the heap (only
when necessary) and marking free memory as reusable.

## <i class="icon-fire" /> Error handling done right

Inko's error handling mechanism forces you to handle errors at the call site.
Methods that may produce an error must include the error type in their
signature, like so:

```inko
fn checked_div(left: Int, right: Int) !! String -> Int {
  left / right
}
```

Here `!! String` signals this method may throw a value of type `String`.

Methods can't lie about their errors: if they specify an error type, they _must_
at some point throw an error, otherwise a compile-time error is produced. This
means our above example won't actually compile until we use `throw` somewhere:

```inko
fn checked_div(left: Int, right: Int) !! String -> Int {
  if right == 0 { throw 'Attempt to divide by zero' }

  left / right
}
```

Methods are also limited to a single error type. This means the following is
invalid:

```inko
fn example(file: ReadOnlyFile) !! String, OutOfMemoryError, IOError, PleaseMakeItStopError {
  ...
}
```

The result of this setup makes it impossible to produce unchecked errors,
without the complexity of error handling as found in other languages.

## <i class="icon-tachometer" /> Concurrency is easy and type-safe

In Inko it's easy to write concurrent code. Inko uses lightweight processes,
scheduled onto a fixed number of OS threads. These processes are defined similar
to classes, and the messages they can receive are defined similar to regular
methods. Objects sent along with messages are moved into the receiving process,
removing the need for (deep) copying them. It's also trivial to take a
synchronous data type and turn it into an asynchronous type. For example, take
this simple stack type:

```inko
class Stack[T] {
  @values: Array[T]

  static fn new -> Self {
    Self { @values = Array.new }
  }

  fn push(value: T) {
    @values.push(value)
  }

  fn pop -> Option[T] {
    @values.pop
  }
}
```

To turn this synchronous type into an asynchronous type, all we need to do is
use `async class` instead of `class`, and `async fn` instead of `fn`:

```inko
async class Stack[T] {
  @values: Array[T]

  static fn new -> Self {
    Self { @values = Array.new }
  }

  async fn push(value: T) {
    @values.push(value)
  }

  async fn pop -> Option[T] {
    @values.pop
  }
}
```

When an instance of our `Stack` is created, Inko automatically spawns a process
for it. The methods `push` and `pop` are messages we can send to this process.
Messages are processed on a first in first out basis. Regular methods in an
`async class` are private to the process spawned for the class. By default, Inko
awaits the result of a message right away, as this is what you want most of the
time:

```inko
async class Stack[T] {
  @values: Array[T]

  static fn new -> Self {
    Self { @values = Array.new }
  }

  async fn push(value: T) {
    @values.push(value)
  }

  async fn pop -> Option[T] {
    @values.pop
  }
}

fn main {
  let stack = Stack.new

  stack.push(42)
  stack.pop # => 42
}
```

If you don't want to wait for the result, just stick `async` in front of the
message like so:

```inko
async stack.pop
```

In this case you'll get a `Future` back, which you can resolve into a value at a
later time.

## <i class="icon-file-code-o" /> Composition over inheritance

Inko has classes, but doesn't support inheritance. Instead, behaviour is
composed together using traits. Traits can define both required and default
methods. This makes code reuse easy, without the troubles that come from using
inheritance. For example, here's how you'd allow converting of a custom type to
a string:

```inko
class Person {
  @name: String
}

impl ToString for Person {
  fn to_string -> String {
    @name
  }
}

fn main {
  let alice = Person { @name = 'Alice' }

  alice.to_string # => 'Alice'
}
```
