---
author: Yorick Peterse
title: "Inko Progress Report: February 2022"
date: 2022-03-02 10:03:21 UTC
---

## Type checking progress

Work on the type-checker continues, with most of the necessary bits and pieces
being implemented. This means we're now able to type-check a small subset of
Inko's standard library. The type-checker only checks types, it doesn't perform
more complicated analysis such as checking if a variable is used after it has
been moved.

Testing at this point is done manually rather than by using unit tests. The
compiler's code is still in a state of flux, and writing good unit tests at this
stage is too time consuming and frustrating, as they'll need frequent
updating/rewriting.

For March we'll focus on resolving any remaining bugs, so that we can check the
entire standard library without errors. We may also start improving test
coverage once we're satisfied with the type-checker.

## Inko now supports sum types

Sum types is something we've been wanting to support for a while, but we never
got around to implementing them. Inko's type system now supports sum types using
the following syntax:

```inko
case class Option[T] {
  case Some(T)
  case None
}
```

This defines the usual Option type with two variants: "Some" (which wraps a
value), and "None". Sum types can also be used in pattern matching. We can
create instances of our sum type like so:

```inko
Option.Some(42) # => Option[Int]
Option.None     # => Option[?], which is further inferred based on usage
```

Here `Some` and `None` are just regular (static) methods defined on the `Option`
type, which is just a regular class under the hood.

An alternative to sum types we considered is "sealed traits". When a trait is
"sealed", it can only be implemented in the same module it's defined in. Such a
setup may look like this:

```inko
sealed trait Option[T] {}

class Some[T] {
  @value: T
}

impl Option[T] for Some {}

class None {}

impl Option[Never] for None {} # We use `Never` since a None
                               # doesn't wrap anything
```

Pattern matching on sealed traits would then look like this:

```inko
match some_option {
  case Some(v) -> print(v)
  case None -> print('Nothing!')
}
```

If `some_option` were typed as `Option[String]`, the compiler can detect that
within the `match` all possible cases are covered.

This approach introduces several problems, which is why we ended up implementing
sum types instead.

First, you need to preserve type information at runtime. Just a pointer to the
class isn't enough for generic types, as both `Array[A]` and `Array[B]` share
the same class. This means you either need some sort of type ID for every type
(so `Array[A]` has ID 1, while `Array[B]` has ID 2), or monomorphise code and
give every generic type their own class. Type IDs would be the most efficient
memory wise, but now the compiler has to map every type to its type ID (e.g. two
occurrences of `Array[A]` in different files should map to the same ID). Since
this information is only used in pattern matching, it feels a bit wasteful.
Monomorphising code in turn isn't that useful in Inko, as we target portable
bytecode instead of machine specific code. It also results in an increase in
compile times and memory usage, and we want to keep both as small as is
reasonable.

The second problem is dispatching. When you have a tagged union, you can use the
tag to dispatch to the appropriate match case. If the IDs are just monotonically
increasing integers starting at zero, you can directly use them as the index to
a jump table. Consider this example:

```inko
case class Letter {
  case A
  case B
  case C
}

match letter {
  case A -> foo
  case B -> bar
  case C -> baz
}
```

A smart compiler may optimise this into `goto jump_table[tag(letter)]`. For
sealed traits we don't have monotonically increasing IDs, as both class
pointers/IDs and type IDs are generated based on the order types are processed
in. Even if two cases happen to use a monotonically increasing identifier, they
may start at some arbitrary value. That is, `Some` may be assigned ID 1234,
while `None` may be assigned ID 1235. The result is that you can't directly map
this to a jump table, instead you have to somehow convert the arbitrary IDs to a
finite range of `0..N`.

The third problem is that sealed traits and classes result in a lot more
boilerplate. Take this sum type for example:

```inko
case class Expr {
  case Add(Expr, Expr)
  case Number(Int)
  case Sub(Expr, Expr)

  fn eval -> Int {
    match self {
      case Add(l, r) -> l.eval + r.eval
      case Sub(l, r) -> l.eval - r.eval
      case Number(v) -> v
    }
  }
}
```

Using sealed traits and classes, we end up with this:

```inko
sealed trait Expr {
  fn eval -> Int
}

class Add {
  @left: Expr
  @right: Expr
}

impl Expr for Add {
  fn eval -> Int {
    @left.eval + @right.eval
  }
}

class Sub {
  @left: Expr
  @right: Expr
}

impl Expr for Sub {
  fn eval -> Int {
    @left.eval - @right.eval
  }
}

class Number {
  @value: Int
}

impl Expr for Number {
  fn eval -> Int {
    @value
  }
}
```

That's a lot more code for such a simple example! Not only that, but the code is
also more spread around, requiring you to jump back and forth to understand the
full picture.

The final problem is type inference. Take this for example:

```inko
sealed trait Option[T] {}

class Some[T] {
  @value: T

  static fn new(value: T) -> Self {
    Some { @value = value }
  }
}

impl Option[T] for Some {}

class None {
  static fn new -> Self {
    None {}
  }
}

impl Option[Never] for None {}

let opt = Some.new(42)
```

Here `opt` is inferred as being of type `Some[Int]`. This leads to problems with
code like this:

```inko
let opt = if some_condition { Some.new(42) } else { None.new }
```

This produces a type error, as the first branch returns `Some[Int]`, while the
second branch returns a `None`. To solve this, we can define our `new` methods
like so:

```inko
class Some[T] {
  @value: T

  static fn new(value: T) -> Option[T] {
    Some { @value = value }
  }
}
```

For `None` this poses a problem: it's not generic, so we can't return
`Option[T]` and have the compiler further infer the concrete type. To solve
that, we can make `None` generic too:

```inko
class None[T] {
  static fn new -> Option[T] {
    None {}
  }
}
```

This is OK as unused class type parameters don't produce compiler errors, though
this may change in the future. Setting that aside, the problem here is
boilerplate: every time we have a sealed trait implemented by N classes, and we
want those class instances to be inferred as the sealed trait, we need a
mechanism of doing so. Going back to our `Expr` example from earlier, this means
you end up with this:

```inko
sealed trait Expr {
  fn eval -> Int
}

class Add {
  @left: Expr
  @right: Expr

  static fn new(left: Expr, right: Expr) -> Expr {
    Add { @left = left, @right = right }
  }
}

impl Expr for Add {
  fn eval -> Int {
    @left.eval + @right.eval
  }
}

class Sub {
  @left: Expr
  @right: Expr

  static fn new(left: Expr, right: Expr) -> Expr {
    Sub { @left = left, @right = right }
  }
}

impl Expr for Sub {
  fn eval -> Int {
    @left.eval - @right.eval
  }
}

class Number {
  @value: Int

  static fn new(value: Int) -> Expr {
    Sub { @value = value }
  }
}

impl Expr for Number {
  fn eval -> Int {
    @value
  }
}
```

Yikes!

## Better pattern matching

Pattern matching used to be limited to simple expressions, and simple
type-checks for non-generic classes. In February we overhauled both the syntax
and semantics, and now it works more like you'd expect from a functional
programming language:

```inko
let x: Option[Option[(Int, String)]] = Option.Some(Option.Some((10, "foo")))

match x {
  case Some(Some((num, _))) -> print(num)
  case _ -> print('something else')
}
```

Guards are also supported:

```inko
let x: Option[Option[(Int, String)]] = Option.Some(Option.Some((10, "foo")))

match x {
  case Some(Some((num, _))) if num > 10 -> print(num)
  case _ -> print('something else')
}
```

Inko also supports `if let` and `while let`:

```inko
if let Some(v) = some_option {
  print(v)
}

while let Some(v) = some_option {
  print(v)
}
```

`let` also supports guards when using sum types as the assigned value:

```inko
let Some(v) = some_option else return
```

In this case the `else` block must return from the surrounding scope.

When pattern matching against a sum type, the variant names don't need to be
fully qualified, as the compiler knows what sum type it's matching against.
Thus, instead of e.g. `Option.Some(v)` or `Option::Some(v)`, you just write
`Some(v)`.

Exhaustiveness checking isn't implemented yet, as we'll do so when lowering the
AST to a more analysis and optimisation friendly IR.

## Potential changes to error handling

With the introduction of sum types and better pattern matching, we're
considering changing Inko's error handling mechanism. Right now, Inko's error
handling mechanism is defined as follows:

1. If a method wants to throw a type, it must state this type in its signature.
   `fn foo !! Int { ... }` means the method `foo` can throw values of type
   `Int`.
1. Methods can't lie about throwing: if a throw type is specified, `throw` must
   occur in the method body.
1. It's a compile-time error to use `throw` in a method that doesn't specify a
   throw type.
1. When calling a method that throws, the error _must_ be handled at the call
   site. You can explicitly propagate the error (`try foo`), explicitly handle
   it (`try foo else (error) { ... }`), or just exit the program with the
   error (`try! foo`).
1. If a throw type is inferred as `Never`, error handling isn't necessary.

As an example, here is how you'd might parse a `String` into an `Int`:

```inko
try Int.parse('42') else 0
```

The problem with this setup is that it doesn't compose well, in particular when
closures are involved. Take this example from the `Iter` type:

```inko
trait Iter[T, E] {
  fn next !! E -> Option[T]

  fn any?(block: do (T) -> Boolean) !! E -> Boolean {
    loop {
      let opt = try self.next
      let val = try opt.get else return false

      if block.call(val) { return true }
    }
  }
}
```

`Iter` is a trait implemented by all iterator types. It specifies two type
parameters: `T` (the output type) and `E` (the throw type). The `any?` method
takes a closure and feeds it every value in the iterator. It stops when it finds
a value for which the closure returned `true`. The closure itself can't throw
due to the lack of a throw type, but the iterator itself _may_ throw. If we
wanted to allow the closure to also throw, we'd have to define our method as
follows:

```inko
fn any?(block: do (T) !! E -> Boolean) !! E -> Boolean {
  loop {
    let opt = try self.next
    let val = try opt.get else return false

    if try block.call(val) { return true }
  }
}
```

This is the first problem: method and closure signatures can get verbose, and in
the method body we must handle errors explicitly even for cases where we
wouldn't actually throw.

Another examples is the `map` method:

```inko
trait Iter[T, E] {
  fn next !! E -> Option[T]

  move fn map[R](block: do (T) -> R) -> Iter[R, E] {
    Enumerator.new {
      let opt = try self.next
      let val = try opt.get else return Option.none

      Option.some(block.call(val))
    }
  }
}
```

`map` doesn't care what its closure does, all it cares about is that it takes an
argument and returns a new value to use for the iterator. But due to the above
signature, the closure can't throw. This means if it performs operations that
may throw, it can't propagate those back to the caller of the `map` method.
Imagine an iterator over files, and for every file we want to map it to the file
size:

```inko
files.map do (file) { file.size }.collect # => [10, 0, 12342, 7298043, ...]
```

Obtaining the file size may fail, so we'd have to handle it:

```inko
files.map do (file) { try file.size }.collect
```

This is invalid because `map` takes a closure that _doesn't_ throw, so we
instead have to do something like this:

```inko
files.map do (file) { try file.size else 0 }.collect
```

Now we lose information about why the operation failed. Sometimes that's fine,
sometimes it's not.

We could fix this by changing `map` to be defined like so:

```inko
trait Iter[T, E] {
  fn next !! E -> Option[T]

  move fn map[R](block: do (T) !! E -> R) -> Iter[R, E] {
    Enumerator.new {
      let opt = try self.next
      let val = try opt.get else return Option.none

      Option.some(try block.call(val))
    }
  }
}
```

Now the closure is allowed to throw, but we have another problem: the throw type
must be the same as that of the input iterator. But what if it's a different
type? Well, we're basically screwed because we'd have error type A from the
input, and error type B for the output, and Inko doesn't allow for multiple
error types. This choice is deliberate: it ensures methods don't list 15
different error types, making handling them difficult.

Which brings us back to sum types. If we instead used sum types, things are a
lot easier:

```inko
trait Iter[T] {
  fn next -> Option[T]

  move fn map[R](block: do (T) -> R) -> Iter[R] {
    Enumerator.new {
      # Option.map maps an Option[A] into an Option[B], with the closure's
      # argument being the wrapped value.
      self.next.map do (value) { block.call(value) }
    }
  }
}
```

And here's what `any?` would look like:

```inko
fn any?(block: do (T) -> Boolean) -> Boolean {
  while let Some(value) = self.next {
    if block.call(value) { return true }
  }

  false
}
```

In this setup `try` would be used to propagate error or none values. That is,
this:

```inko
try read_file
```

Would be the same as this:

```inko
let Ok(v) = read_file else (err) return err
```

This way you can handle `Result`/`Option` values, without the need for
explicitly propagating values to the caller.

In conclusion, using sum types for error handling would make composition and the
use of closures easier. The cost of having to wrap both OK and error values is
non-zero, but a sufficiently smart Inko compiler should be able to optimise this
to some degree.

## Generators are removed

Inko has supported generators for a while now. Initially generators were
first-class types in the VM, but a while back we decided to instead use compiler
transformations as this gives us greater control over how generators work.
Generators were introduced back when Inko didn't have an Option type or sum
types, which meant that writing iterators was cumbersome. When we introduced the
Option type a while back this made writing iterators easier, but we kept
generators around.

Supporting generators using compiler transformations isn't easy. Take this
method for example:

```inko
fn numbers => Int {
  yield 10

  let num = 42

  yield num
  ...
}
```

Here `=> Int` signals the method yields values of type `Int`. Using compiler
transformations, this would be turned into the following:

```inko
class NumbersGenerator {
  @state: Int
  @num: Any
}

impl Iter[Int] for NumbersGenerator {
  fn next -> Option[Int] {
    match @state {
      case 0 -> {
        let val = Option.Some(10)

        @state = 1
        @num = 42

        val
      }
      case 1 -> {
        let val = Option.Some(@num)
        @num = undefined
        @state = 2

        val
      }
      case 2 -> {
        @state = 3
        Option.None
      }
      case _ -> {
        panic("can't resume a generator that finished")
      }
  }
}
```

That is: we generate some sort of match that determines what code to run. Any
variable that survives a `yield` must be stored in the generator, so the next
state can use it. We also have to clear the appropriate fields after their
values have been moved out of the generator, so we don't drop/deallocate them
twice.

Instead of implementing all the complexity necessary to support generators,
we've opted to stop supporting them in favour of a new type: `Enumerator`. This
type is an iterator that takes a closure and uses it to feed values into the
iterator. It's a shockingly simple type:

```inko
class Enumerator[T, E] {
  @block: do !! E -> Option[T]
}

impl Iter[T, E] for Enumerator {
  fn next !! E -> Option[T] {
    @block.call
  }
}
```

It gets even simpler if we use sum types for error handling:

```inko
class Enumerator[T] {
  @block: do -> Option[T]
}

impl Iter[T] for Enumerator {
  fn next -> Option[T] {
    @block.call
  }
}
```

Now you may think to yourself: "Hey, didn't I see that Enumerator type in
earlier examples?". Yes, you did: the examples shown earlier use this exact type
to make writing iterators easy, without the need for complex compiler
transformations.

Fun fact: before we introduced generators we had a similar setup (this was back
in 2019), though it wasn't as easy to use due to the lack of an Option type and
sum types (Inko still had optional/nillable types back then).

And that's all for February! If you'd like to follow along with the progress
made, we recommend joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). If
you'd like to support Inko financially, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
