---
{
  "title": "The Inko programming language"
}
---

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
compared to languages such as Rust. The use of single ownership also means more
predictable behaviour and performance, and not having to spend a long time
adjusting different garbage collection settings.

# Inko is safe

With Inko you never again have to worry about NULL pointers, use-after-free
errors, unexpected runtime errors, data races, and other types of errors
commonly found in other languages. For optional data Inko provides an `Option`
type, which is an algebraic data type that you can pattern match against. Inko
supports both mutable and immutable references, allowing you to restrict
mutation where necessary.

# Concurrency made easy

Inko uses lightweight processes for concurrency, and its concurrency model is
inspired by [Erlang](https://www.erlang.org/) and
[Pony](https://www.ponylang.io/). Processes are isolated from each other and
communicate by sending messages. Processes and messages are defined as classes
and methods, and the compiler type-checks these to ensure correctness.

The compiler ensures that data sent between processes is unique, meaning there
are no outside references to the data. This removes the need for (deep) copying
data, and makes data races impossible. Inko also supports multi-producer
multi-consumer channels, allowing processes to communicate with each other
without needing explicit references to each other.

Here's how you'd implement a simple concurrent counter:

```inko
import std.sync (Future, Promise)

type async Counter {
  let mut @value: Int

  fn async mut increment {
    @value += 1
  }

  fn async get(promise: uni Promise[Int]) {
    promise.set(@value)
  }
}

type async Main {
  fn async main {
    let counter = Counter(value: 0)

    counter.increment
    counter.increment

    match Future.new {
      case (future, promise) -> {
        counter.get(promise)
        future.get # => 2
      }
    }
  }
}
```

# Error handling done right

Inko uses a form of error handling inspired by Joe Duffy's excellent article
["The Error Model"](http://joeduffyblog.com/2016/02/07/the-error-model/). Errors
are represented using the algebraic type "Result", and Inko provides syntax
sugar in the form of `try` and `throw` to make error handling easy. Critical
errors that can't/shouldn't be handled are supported in the form of "panics",
which abort the program when they occur.

For example, here's how you'd handle errors when opening a file and calculating
its size:

```inko
import std.fs.file (ReadOnlyFile)
import std.stdio (Stdout)

type async Main {
  fn async main {
    let size = ReadOnlyFile
      .new('README.md'.to_path)          # => Result[ReadOnlyFile, Error]
      .then(fn (file) { file.metadata }) # => Result[Metadata, Error]
      .map(fn (meta) { meta.size })      # => Result[Int, Error]
      .or(0)

    Stdout.new.print(size.to_string) # => 1099
  }
}
```

# Efficient

Inko aims to be an efficient language, though it doesn't aim to compete with
low-level languages such as C and Rust. Instead, we aim to provide a compelling
alternative to the likes of Ruby, Erlang, and Go.

Inko uses a native code compiler, using [LLVM](https://llvm.org/) as its
backend, and aims to provide a balance between fast compile times and good
runtime performance. The native code is statically linked against a small
runtime library written in Rust, which takes care of scheduling processes,
non-blocking IO, and provides various low-level functions.

# Pattern matching

Inko supports pattern matching on a variety of types, such as tuples and
algebraic data types:

```inko
type async Main {
  fn async main {
    match [10, 20].opt(1) {
      case Some(number) -> number # => 20
      case None -> 0
    }

    match (10, 'hello') {
      case (10, 'hello') -> 'foo'
      case (20, _) -> 'bar'
      case _ -> 'baz'
    }
  }
}
```

You can also match against literals such as integers and strings, and against
regular classes:

```inko
type Person {
  let @name: String
  let @age: Int
}

type async Main {
  fn async main {
    let alice = Person(name: 'Alice', age: 42)

    match alice {
      case { @name = name } -> name # => 'Alice'
    }
  }
}
```

Pattern matching is compiled down to decision trees, and the compiler tries to
keep their sizes as small as possible. The compiler also ensures that all
patterns are covered.
