---
author: Yorick Peterse
title: "Inko Progress Report: April 2022"
date: 2022-05-02 14:44:45 UTC
---

With April behind us it's time for another progress report.

## The mid-level intermediate representation

A lot of progress has been made towards implementing Inko's mid-level IR (MIR).
MIR is a graph based linear IR, lowered from the high-level IR (HIR), which is a
tree (basically the AST plus type information). MIR is used for enforcing move
semantics, optimisations (once we write any optimisation passes that is), and
more.

In April we managed to implement most of the code needed for lowering HIR to
MIR. Pattern matching is implemented for `let` expressions, but we have yet to
implement it for `match` expressions. We've also yet to implement lowering of
closures and several other HIR nodes. Thanks to MIR, we can detect incorrect
code such as the following:

```inko
fn example(numbers: Array[Int]) {
  drop(numbers)
  numbers.push(42) # Error: 'numbers' can't be used as it has been moved
}

fn drop(numbers: Array[Int]) {}
```

As part of lowering to MIR we also generate the code necessary to drop variables
when they are no longer in use. Take this code for example:

```inko
fn example(numbers: Array[Int]) {
  # `numbers` dropped at the end of this scope
}
```

The MIR for this method is as follows:

<img src="/images/april-2022-progress-report/mir_simple.svg"
    alt="The MIR for an empty method"
    width="200" />

`b0` is a basic block in the method, and contains the instructions of just that
block. The instruction `r3 = nil` stores `nil` in register `r3`, which is later
returned by the `return` instruction. The instructions `check_refs`, `drop` and
`free` are used whenever an owned value goes out of scope.

The `check_refs` instruction checks if there are any references pointing to the
value stored in register `r1` (the `numbers` argument). This is needed to ensure
we don't end up with dangling references to the value elsewhere.

The `drop` instruction calls a generated method called `$dropper`. This method
runs the destructor of `r1` (if it has any), then calls `$dropper` on any of its
fields. We use a special instruction for this as the `$dropper` method may be
generated _after_ the above instructions are generated. This means that when we
want to generate this code, the necessary method information may not yet be
available.

The `free` instruction reclaims the memory of the value stored in register `r3`,
allowing future allocations to reuse the memory.

As MIR is a graph based IR, branches are represented as edges in the graph. Take
this code for example:

```inko
fn example -> String {
  if true {
    'foo'
  } else {
    'bar'
  }
}
```

The MIR for this method is as follows:

<img src="/images/april-2022-progress-report/mir_branch.svg"
    alt="The MIR of an if expression"
    width="400" />

The first block (`b0`) is for the code that precedes the `if`. Since the `if` is
the first expression, this block is empty. Empty blocks will be removed in a
later stage of the compiler.

The `branch` instruction checks if a register is true or false and branches to
the corresponding block. Here we also see a `move` instruction. This instruction
"copies" (it doesn't have to actually involve a copy) a value from one register
to another, marking the source register as unavailable.

MIR is also able to handle conditional drops. Take this code for example:

```inko
import std::drop::(drop)

fn example {
  let numbers = [10]

  if true {
    drop(numbers)
  }
}
```

When lowering this to MIR, we (more or less) lower this into the following:

```inko
import std::drop::(drop)

fn example {
  let numbers = [10]
  let numbers_alive = true

  if true {
    drop(numbers)
    numbers_alive = false
  }

  if numbers_alive {
    drop(numbers)
  }

  return nil
}
```

The approach is similar to (and taken directly from) Rust: for every owned value
allocated or received as an argument, we generate an extra variable invisible to
the user, called a "drop flag". When the value is dropped, we write `false` to
the drop flag. At the end of the scope we check the drop flag, only dropping its
corresponding value if the drop flag is still `true`.

If a variable is always dropped unconditionally, the drop flag is unused. Once
we implement dead code removal, this results in no drop flags being present
_unless_ necessary.

If you're curious, the MIR graph for a conditional drop looks like this:

<img src="/images/april-2022-progress-report/mir_conditional_drop.svg"
    alt="The MIR of a conditional drop"
    width="400" />

If you're wondering what that poor b1 basic block is doing up there all alone:
`let` supports patterns, and those patterns may fail to match. If that's the
case, a `else` block must be provided. For example:

```inko
let (a, 10) = (10, 20) else return
```

The `b1` block is generated for that `else` case, and we do so even if `else`
isn't present, as this makes parts of generating MIR easier. At a later stage in
the compiler we'd remove empty basic blocks anyway, so this isn't a problem.

The last part of MIR we'd like to show is detecting unreachable code. The use of
a graph based IR makes this trivial: unreachable code is just a basic block that
has no incoming edges, and has at least one instruction. Take this code for
example:

```inko
fn example {
  loop {
    'loop body'
  }

  'after the loop'
}
```

The MIR for this method is as follows:

<img src="/images/april-2022-progress-report/mir_unreachable.svg"
    alt="The MIR of an unreachable expression"
    width="400" />

Here we can see that block b2 is unreachable, and as a result the compiler emits
a warning like so:

```
test.inko:6:3 warning(unreachable): This expression is unreachable
```

## Type-safe concurrency

This is something we forgot to discuss in previous progress reports: Inko's
message sending is now fully type-safe. In the past this wasn't entirely the
case: owned values can be moved when references to them exist, which is a big
part of what makes Inko's memory management strategy less frustrating to use
compared to Rust. This introduces a problem though: we could send a value to
another process, while retaining a reference to the sent value. This can then
lead to race conditions.

To solve this we looked at how other languages with a similar concurrency model
approach this problem. We ended up basing the solution on how
[Pony](https://www.ponylang.io/) handles concurrency, which in turn is based on
the paper ["Uniqueness and Reference Immutability for Safe
Parallelism"](https://www.microsoft.com/en-us/research/publication/uniqueness-and-reference-immutability-for-safe-parallelism/).
Unlike Pony, we don't introduce a large list of reference capabilities, making
the setup more accessible.

The underlying idea is quite simple: you can only send a value between processes
if it has no references to it. This is enforced using the type `uni T` (`iso T`
in the linked paper).

A value/type that you can send between processes is called a "sendable"
value/type. Besides a `uni T` the types `Int`, `Float`, `String` and `Nil` are
also sendable, as these are value types and copied when sent between processes.

You can create a `uni T` using a `recover` expression. This expression has
access to outer variables and fields, but _only_ if they are also of type `uni
T`. This means that any regular owned values (type `T`) created in the `recover`
expression can't have any references pointing to them from the outside of the
`recover` expression. This in turn means it's safe to turn it into a `uni T` by
returning it from the expression, as at that point no outside references to it
can exist. Note that it's totally fine for a `uni T` to store (indirectly) a
reference to itself.

If a `uni T` defines any fields they can't be accessed, as doing so might result
in a violation of the uniqueness constraint. Methods _can_ be called, but only
if their arguments (if any) are sendable, and the return/throw type (if any) is
also sendable.

Using these rules, here's how you'd implement a concurrent stack:

```inko
class async Stack[T] {
  let @values: Array[uni T]

  # `fn async` means this method can be called by other processes.
  # `mut` is added so we can modify `@values`.
  fn async mut push(value: uni T) {
    @values.push(value)
  }

  fn async mut pop -> uni Option[uni T] {
    # `Array.pop` returns a regular `Option` instead of a `uni Option`, so we
    # have to manually create a new one and recover it into a `uni Option`.
    match @values.pop {
      case Some(v) -> recover Option.Some(v)
      case None -> recover Option.None
    }
  }
}

class Person {
  let @name: String
}

fn main {
  let stack = Stack { @values = recover [] }

  stack.push(recover Person { @name = 'Alice' })
  stack.push(recover Person { @name = 'Bob' })

  stack.pop # => Option.Some(Person { @name = 'Bob' })
}
```

While this approach to concurrency introduces a bit of noise (in the form of
`uni` in type annotations, and `recover` in expressions), we believe it to be a
good start. In the future we may add more features to reduce some of this noise.

If you want to turn a `uni T` back into a `T`, you use a `recover` and return
the `uni T`:

```inko
fn example(value: uni Person) -> Person {
  recover value
}
```

A `uni T` can also be moved into a regular `T`:

```inko
fn foo(value: uni Person) -> Person {
  bar(value)
}

fn bar(value: Person) -> Person {
  value
}
```

Doing this the other way around is obviously not allowed.

## Removal of "if let" and "while let"

For short while, Inko supported `if let` and `while let` expressions, inspired
by Rust (which in turn took this from Swift). These expressions _let_ you (we're
not sorry for that one) write an `if` or `while` that acts on the result of a
match like so:

```inko
if let Some(value) = Option.Some(42) {
  print(value)
} else {
  print(0)
}

while let Some(value) = stack.pop {
  print(value)
}
```

Such expressions end up complicating matters in ways we didn't expect when
implementing them.

The first problem is that these expressions introduce yet _another_ way to
perform pattern matching (besides `let` and `match`). We prefer having fewer
ways of doing the same thing, as we believe this makes it easier for developers
to use Inko. It also means you end up with a more consistent codebase, as you
won't end up with two developers where one uses `if let` and the other uses a
regular `match`.

The second problem is that the behaviour and rules of `let` change based on the
context it's used in. A regular `let` expects an irrefutable pattern (= the
pattern always matches) _unless_ it's given an `else` block, in that case a
refutable pattern (= a pattern that _might_ match) _is_ allowed. But inside an
`if` and `while` this changes: by default it _can_ have a refutable pattern, and
it _can't_ have an `else`. This complicates not only the parser, but also the
type-checker and the code that lowers HIR to MIR. Things get more confusing if
you consider that an `if` can contain a scope expression which may contain a
`let` like so:

```inko
if {
  let thing = some_value

  thing == another_thing
} {
  ...
}
```

While you shouldn't write code like this, it's technically correct Inko code,
and as such the compiler has to decide how it's going to handle this. This ends
up complicating the compiler and language, for something we believe isn't worth
the trouble.

The third problem is that the syntax is confusing if you were to allow chaining
of `let` expressions, and requires further parser changes so this is parsed as
you'd expect. Take this code for example:

```inko
if let Some(a) = foo and let Some(b) = bar {
  print(a + b)
}
```

Without any special handling in the parser, this is parsed like so:

```inko
if let Some(a) = (foo and let Some(b) = bar) {
  print(a + b)
}
```

That's not what we want, instead we want it to be parsed like so:

```inko
if (let Some(a) = foo) and (let Some(b) = bar) {
  print(a + b)
}
```

To achieve this we had to special-case the parsing rules for `if` when it
encounters a `let`, change how the type-checker handles this, and adjust the
lowering to MIR as well.

The last problem is that this syntax just isn't that useful in Inko. `while`
loops are rare, as in most cases you're better off using iterators. Iterators in
turn are easy to write, and in most cases only need a small amount of code.
Since we support expressions like `let Some(v) = value else return`, `if let`
isn't needed either, as you either use a `let else` or just a regular `match`
for more complex patterns. Take this `while let` for example:

```inko
while let Some(value) = stack.pop {
  print(value)
}
```

In Inko, you'd write the following instead:

```inko
loop {
  let Some(value) = stack.pop else break

  print(value)
}
```

It only needs one extra line (ignoring whitespace), but achieves the exact same
results, without the need for `if let`.

With all this in mind, we decided to remove support for `if let` and `while
let`, in favour of using iterators (instead of `while` loops, where this makes
sense), and using `let else` to return/break/etc instead of nesting (or
chaining) `if let` expressions.

## Plans for May

In May we'll continue working on MIR. In particular we'll start working on
lowering `match` expressions and performing exhaustiveness checking, as well as
starting work on lowering closures.

If you'd like to follow along with the progress made, we
recommend joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). If
you'd like to support Inko financially, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
