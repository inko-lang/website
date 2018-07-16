---
title: Frequently Asked Questions
html_class: faq
keywords:
  - inko
  - faq
  - frequently asked
description: Frequently asked questions about the Inko programming language.
---

1. TOC
{:toc}

## The Inko project

### Where does the name come from?

"Inko" ("インコ") is Japanese for parakeet / parrot. Inko is an object oriented
language that uses message passing. In a way, objects talk to each other, much
like parrots can "talk" by mimicking the human voice. The creator of Inko also
happens to like parrots.

### Who is the creator of Inko?

[Yorick Peterse](https://yorickpeterse.com/).

### What license does Inko use?

Inko is licensed under the [Mozilla Public License version
2.0](https://www.mozilla.org/en-US/MPL/2.0/).

### Why does Inko use the MPL 2.0?

The MPL 2.0 license is a permissive language that covers important topics, such
as patents, and better describes who owns the source code (compared to the MIT
license). It also comes with some requirements such as:

* Changes made to the software have to be made available to the public.
* A copy of the license must be included when distributing the software.
* Modifications of the software must use the same (or a compatible) license.

All of this better protects the authors and the software, and makes it more
clear to users (and especially large organisations) what to expect.

For more information about the MPL 2.0 you can refer to the [MPL 2.0
FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/), or the [MPL 2.0 entry on
choosealicense.com](https://choosealicense.com/licenses/mpl-2.0/).

### Can I use Inko for a proprietary project?

Yes. The MPL 2.0 is not a viral license. This means that the MPL 2.0 license
only applies to Inko's own source code, and not any projects that link with it
(e.g. your own software).

### Why host on GitLab.com, and not GitHub?

GitLab offers more features than GitHub, and comes with built-in continuous
integration support.

### What languages were a source of inspiration for Inko?

In no particular order: Smalltalk, Self, Ruby, Erlang, and Rust.

### Inko's concurrency model looks familiar to the model used by Erlang, is this intentional?

Yes. Inko's concurrency model is heavily inspired by Erlang.

## The language

### Why use curly braces?

Curly braces are by far the most common way of starting and terminating blocks
of code, such as functions. This hopefully makes it easier to get used to Inko.

Curly braces integrate better into editors, as many have support for
automatically inserting them, or jumping to a closing curly brace.

Finally, curly braces make the code more compact without sacrificing
readability.

### Why do I have to import a module just to write to STDOUT or STDERR?

1. Not every program (or module) has to write to STDOUT or STDERR.
1. Exposing some sort of `print` method by default could lead to conflicting
   methods in a module.
1. You can not import _just_ a method from a module, instead a receiver is
   always required. This would require importing a module by default, but for
   many modules this simply isn't necessary.

### Why is the keyword for blocks called "do"

This is taken from Ruby, which uses a keyword with the same name to start a Ruby
closure.

### Why do certain methods take a "lambda", instead of a block?

Lambdas are blocks that can't capture any local variables. They are primarily
used for spawning processes, or starting other operations where the block may
outlive the scope that it is defined in.

### What was the inspiration for the error handling model of Inko?

An article titled [The Error Model](http://joeduffyblog.com/2016/02/07/the-error-model/),
by [Joe Duffy](http://joeduffyblog.com/).

### Why not use some sort of Result type for errors?

Result types and similar solutions impose a runtime cost on the happy path, even
when an error never occurs. Inko's error model doesn't suffer from the same
problem.

### Why does sending a message to Nil return another Nil?

This drastically simplifies the amount of if-nil-then-that checks. Say you want
to retrieve a user from a database, get their location details, then display
their city. If the user is not found, you should display an empty string. In a
language such as Ruby, you would have to write the following:

```ruby
user = find_user(email: 'alice@example.com')

if user && user.location
  user.location.city
else
  ''
end
```

In recent versions of Ruby you can shorten this down to the following, though it
is effectively the same code:

```ruby
user = find_user(email: 'alice@example.com')

user&.location&.city || ''
```

In Inko, we would instead write the following:

```inko
user = find_user(email: 'alice@example.com')

user.location.city
```

And if we want to return a string right away:

```inko
user = find_user(email: 'alice@example.com')

user.location.city.to_string
```

While this particular example is fairly basic, in real world applications this
allows you to drastically reduce the amount of code necessary to deal with
optional values. And none of this requires additional syntax sugar.

### Isn't that annoying? How will I know where a Nil originated from?

If you could blindly pass a Nil to other methods, then yes this could be
annoying. However, Inko doesn't allow this when using statically typed methods.
For example, if a method takes a "User" object you can not pass a Nil to it.
The only time you can pass a Nil as an argument is when this argument takes an
optional type (e.g. a `?User`), or simply takes Nil itself.

This prevents Nil values from "leaking" into other methods unexpectedly. This in
turn makes it very easy to figure out where a Nil comes from, because you rarely
have to deal with a Nil that did not originate directly from your own code.

### But what if I don't want to deal with a Nil value? For example, when saving data to a database.

In that case you can always send `if`, `if_true`, or similar messages to the
object and act accordingly. Just because sending an unknown message to Nil
produces another Nil doesn't mean you _never_ should send these messages to Nil.

### How do I convert an optional type to a non optional type?

If you have an optional `?T`, you can tell the compiler to treat it as a `T` by
using prefixing the expression with a `*`. For example, if `user` is a `?User`
then `*user` will inform the compiler that the return value of this expression
is a `User`. This operator is called the "unpack operator", because it "unpacks"
a `?T` into a `T`.

Keep in mind that this only serves as a hint to the compiler, it will _not_
generate any sort of runtime code to verify if the expression is Nil or not.
This means you should always check if you are dealing with a Nil or not when
using this operator:

```inko
let number: ?Integer = Nil

# This will blow up, because "number" is Nil.
*number + 5

# This is safe, and the recommended way of doing things.
number.if_true {
  *number + 5
}
```

### Why do I have to include error types in my method signatures, but panics don't require any additional information?

Virtually every method can panic (e.g. when running out of memory). This would
lead to _very_ verbose method signatures.

### Does Inko support reflection?

Yes, there are two modules for this:

1. `std::reflection`
1. `std::mirror`

The `std::reflection` module provides a few simple reflection methods that
should have as little overhead as possible, such as `std::reflection.kind_of?`.

The `std::mirror` module provides a more powerful reflection system, based on
the concept of [mirrors](https://en.wikipedia.org/wiki/Mirror_(programming)).

### OK so how do I use mirrors?

You import `std::mirror`, create a mirror for your object, then send messages to
it to get the data you need. For example, we can retrieve the argument names of
a block as follows:

```inko
import std::mirror

let block = do (number: Integer) { number * 2 }
let block_mirror = mirror.reflect_block(block)

block_mirror.argument_names # => ['self', 'number']
```

### Why do my methods and blocks define a "self" argument?

This argument is used to store the receiver of methods, it is generated by the
compiler.

Closures don't use the argument, instead they capture the outer local variable
called `self`. Lambdas ignore the argument as well, and instead explicitly
define `self` and set it to the object of the module the lambda is defined in.

### How can I refer to the current module?

You can use the `ThisModule` constant for this, which contains the module that
the constant is referenced from. This can be used when an object's method is the
same as a module method, and you want to call the module method from the
object's method:

```inko
def example {}

object Person {
  def example {
    ThisModule.example
  }
}
```

### How do I write a unit test?

You can use `std::test` for this:

```inko
import std::test
import std::test::assert

test.group 'Integer.+', do (group) {
  group.test 'Summing two Integers', {
    try assert.equal(1 + 2, 3)
  }
}

test.run
```

### How does the runtime perform low level operations, such as opening a file?

The runtime uses what is known as "virtual instructions" for this. These
instructions look like regular message sends, but are compiled directly into
virtual machine instructions. Virtual instructions always use the constant
`_INKOC` as the receiver, for example:

```inko
_INKOC.integer_equals(10, 10)
```

This code would be directly compiled into the `IntegerEquals` instruction. These
virtual instructions are used in various places as the basic building blocks of
the runtime.

You should never use these instructions directly, as they are not part of the
public API and may change (or be removed) at any time.

## The compiler

### Why is the compiler written in Ruby?

Currently Inko is not feature complete enough to write a compiler for itself.
This meant the creator had to use a different language, and Ruby happened to be
a language they were most comfortable with.

### Why not write the compiler in Rust, just like the VM?

Prior to the compiler being written in Ruby, the author did attempt to write it
in Rust instead. Unfortunately, the author spent a lot of time fighting Rust's
strict type system and borrow checker. After a month or two the author decided
to give up, and write the compiler in Ruby instead.

### Will the compiler always be written in Ruby?

No. Once Inko is feature complete enough we aim to rewrite the compiler in Inko
itself.

### Does the compiler perform any work in parallel?

Not at the moment.

### Does the compiler support incremental compilation?

Not at the moment, but we hope to add support for this one day.

## The virtual machine

### Why write the VM in Rust?

While the creator has experience with other systems languages such as C, they
did not feel comfortable writing a virtual machine in these languages. Rust
makes it much harder to shoot yourself in the foot, comes with a nice package
manager, built-in unit testing, type inference, and many other features not
found in C or C++.

### Why use a garbage collector?

Manually managing memory like one does in C is prone to error. Compiler assisted
memory management, such as used by Rust, is less error prone but often more
complicated to use. Garbage collection makes memory management easy (for the
user), at the cost of (potentially) less efficient memory usage.

The creator felt that using a garbage collector strikes a nice balance between
good memory usage, and ease of use.

### What garbage collection algorithm is used?

The garbage collector is a generational, parallel garbage collector, based on
[Immix](http://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf).
While Immix is not very popular, it is an excellent garbage collection
algorithm.

Inko is currently the only programming language out there (that we know of) that
fully implements Immix. [JikesRVM](https://www.jikesrvm.org/) also fully
implements Immix, but is targeted towards virtual machine research, and not
production software.

### How does Immix work?

The Immix paper describes this in great detail, but the _very_ brief summary is
as follows:

* Memory is divided into 32 KB aligned blocks, which in turn are divided into
  "lines". Each line is 128 aligned bytes.
* A global allocator is tasked with allocating blocks from the system, and
  handing these off to thread-local (or in case of Inko process local)
  allocators.
* Objects are allocated into free lines of blocks that still have one or more
  lines available, using bump allocation.
* The garbage collector does not operate on individual objects, instead it
  operates on lines. This means it reclaims entire lines, instead of individual
  objects.
* The garbage collector uses a set of statistics to determine which blocks can
  be reused, which are full, and which ones need to be evacuated.
* Evacuating means moving objects from one block to another. This will reuse
  existing free blocks. The decision to do so is made based on statistics from a
  previous garbage collection.
* Evacuating of objects happens while tracing through all live objects, removing
  the need for a separate pass over the entire heap.
* Free blocks are returned to the global allocator.

### Why not use OS threads, instead of green threads?

While the overhead of starting OS threads is not that big, it is still quite a
bit bigger than simply allocating a lightweight structure and storing this
somewhere. OS threads also typically allocate a certain stack size from the
start.

Green threads give us greater control, and use fewer resources. This allows one
to spawn a large number of green threads (known as "processes" in Inko), without
using a lot of memory.

The use of green threads does require a custom scheduler, which adds extra
complexity. The creator felt that this trade-off was worth it, because it
ultimately makes it much easier and less scary to run many concurrent processes.

### Does the virtual machine support finalisation?

Yes, but this is not exposed to the language. The virtual machine uses an
internal finalisation mechanism to clean up various resources that belong to
garbage collector objects.

Exposing finalisation can lead to a great deal of problems, and makes both the
language and virtual machine much more complex. To solve this problem, the
author decided to simply not expose a finalisation mechanism.

### Does this mean my program will leak resources, such as sockets, if I don't close them?

No. When a process terminates, its memory is cleaned up, even in the event of a
panic. This means that by the time a program terminates, all resources will be
cleaned up.

Keep in mind that this clean up will not happen the moment an object is garbage
collected, instead it will happen at some future point in time. This means it's
best to explicitly dispose of external resources the moment you no longer need
them.

### Does the virtual machine guarantee resources are cleaned up upon termination?

Aside from any bugs preventing this from happening, yes. Inko makes use of
Rust's drop semantics to ensure that when a program terminates all of its
resources (memory, sockets, etc) are cleaned up before shutting down.
