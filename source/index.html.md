---
title: Inko Programming Language
created_at: 2018-07-09
description: >
  Inko is a general-purpose, statically-typed, and easy to use programming
  language.
---

# Safe

With Inko you never again have to worry about NULL pointers, use-after-free
errors, unexpected runtime exceptions, and other types of errors commonly
found in other languages.

For optional data Inko provides an `Option` type, which is an algebraic data
type that you can pattern match against. For example:

```inko
let numbers = [10, 20, 30]

match numbers.get(1) {
  case Some(value) -> value # => 10
  case None -> 0
}
```

Mutability in turn is restricted to references that allow mutations. This makes
it more difficult to mutate data by accident:

```inko
let a = [10]
let b = ref a

a.push(20) # "a" is mutable, so this is OK
b.push(30) # "b" is immutable (due to the use of `ref`), so this isn't OK
```

# Efficient

Inko aims to be an efficient language, though it doesn't aim to compete with
low-level languages such as C and Rust. Instead, we aim to provide a compelling
alternative to the likes of Ruby, Erlang, and Go.

Inko uses a bytecode interpreter written in Rust, but the long term plan is to
switch to compiling to machine code. The interpreter has a small memory
footprint, and starts up in less than two milliseconds.

# Deterministic automatic memory management

Inko doesn't rely on garbage collection to manage memory. Instead, Inko relies
on single ownership and move semantics. Values start out as owned and are
dropped when they go out of scope:

```inko
let numbers = [10, 20, 30]

# "numbers" is no longer in use here, so it's dropped.
return
```

These values can be borrowed either mutably or immutably. Inko allows multiple
borrows (both mutable and immutable borrows), and allows moving of the borrowed
values while borrows exist:

```inko
let a = [10, 20, 30]

# All of this is perfectly fine:
let b = ref a # borrows "a" immutably
let c = mut a # borrows "a" mutably
let d = a     # moves "a" into "d"
```

This gives you the benefits of single ownership, but at a fraction of the cost
compared so similar languages such as Rust. The use of single ownership also
means more predictable behaviour and performance, and not having to spend a long
time adjusting different garbage collection settings.

Inko doesn't provide its own allocator, instead it relies on the system
allocator. This reduces the binary size, and allows you to take advantage of
high performance allocators such as [jemalloc](https://jemalloc.net/).

# Type-safe concurrency

Inko uses lightweight processes for concurrency, and its concurrency model is
inspired by [Erlang](https://www.erlang.org/) and
[Pony](https://www.ponylang.io/). Processes are isolated from each other and
communicate by sending messages. Processes and messages are defined as classes
and methods, and the compiler type-checks these to ensure correctness. Here's
how you'd implement a simple concurrent counter:

```inko
class async Counter {
  let @value: Int

  fn async mut add(value: Int) {
    @value += value
  }

  fn async value -> Int {
    @value
  }
}

let counter = Counter { @value = 0 }

counter.add(1)
counter.add(1)
counter.value # => 2
```

By default, the sending process awaits the result of a message. This can be
changed using the `async` keyword, resulting in a `Future` being returned that
can be resolved later:

```inko
counter.add(1) # => nil
counter.add(1) # => nil

let future = async counter.value # => Future[Int, Never]
let value = future.await         # => Int
```

The compiler ensures that data sent between processes is unique, meaning there
are no outside references to the data. This removes the need for (deep) copying
data, and makes data races impossible. Sending value types requires no extra
work, but for other types you need to use a `recover` expression to ensure there
are no outside references to the data:

```inko
class async Stack[T] {
  let @values: Array[uni T]

  fn async mut push(value: uni T) {
    @values.push(value)
  }

  # ...
}

let stack = Stack { @values = recover [] }

stack.push(recover [10, 20, 30])
```

Inside a `recover` expression, only values of type `uni T` and value types are
available. When these values are used, they are moved into the expression.
Because of this, any owned value (a `T`) created inside a `recover` can be
converted into a `uni T` (or the other way around), as no references to the
value can exist outside the `recover` expression:

```inko
let a = [10, 20, 30]

# This isn't valid, because "a" is of type `Array[Int]`, and such values aren't
# visible to `recover` expressions.
recover a

# This however is perfectly fine, and returns a `uni Array[Int]`:
recover [10, 20, 30]
```

In practise, `recover` expressions are only used at the boundary between
processes. This makes it possible to send data between processes, without
runtime overhead, and without an overly complex type system.

# Error handling done right

Inko uses a form of exception handling inspired by Joe Duffy's excellent [The
Error Model](http://joeduffyblog.com/2016/02/07/the-error-model/) article. The
compiler enforces error handling whenever a method may throw, and methods can't
throw unless annotated accordingly:

```inko
# This is invalid because the method isn't annotated with a throw type.
fn invalid {
  throw 42
}

# This is also invalid, because while the method specifies a throw type, it
# never actually throws a value.
fn invalid !! Int -> Int {
  42
}

fn valid !! Int {
  throw 42
}
```

Methods may only throw a single error type, drastically simplifying error
handling:

```inko
# This is invalid because a method can't specify more than one throw type.
fn invalid !! String, Int {
  throw 42
}
```

Error handling at the call site is done using the `try` or `try!` keyword:

```inko
try example                    # If `example` throws, the value is thrown again.
try example else (err) { ... } # Handle the thrown value explicitly if it occurs.
try! example                   # Simply panic (= terminate) the program if a value is thrown
```

The overhead is minimal, as Inko doesn't use implicit stack unwinding, and
errors don't include extra data (e.g. stack traces) unless explicitly added.

# Pattern matching

Inko supports pattern matching on a variety of types, such as tuples and
algebraic data types:

```inko
match [10, 20].get(1) {
  case Some(number) -> number # => 20
  case None -> 0
}

match (10, 'hello') {
  case (10, 'hello') -> 'foo'
  case (20, _) -> 'bar'
  case _ -> 'baz'
}
```

You can also match against literals such as integers and strings, and against
regular classes:

```inko
class Person {
  let @name: String
  let @age: Int
}

let alice = Person { @name = 'Alice', @age = 42 }

match alice {
  case { @name = name } -> name # => 'Alice'
}
```

Pattern matching is compiled down to decision trees, and the compiler tries to
keep their sizes as small as possible. The compiler also ensures that all
patterns are covered.
