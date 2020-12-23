---
title: Inko 0.9.0 released
date: 2020-12-23 17:00:00 UTC
---

Merry Christmas! Inko 0.9.0 has been released, with a new manual, fewer
dependencies, the removal of nullable types, support for generators, pattern
matching, and much more!

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

For the full list of changes, take a look at [the changelog][changelog].

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/).

## A brand new manual

The old Inko manual that was part of the website is replaced with a new manual
based on [mkdocs](https://www.mkdocs.org/). The manual is now part of the main
Inko repository, instead of the website repository. This makes it easier to
contribute documentation changes. These changes also allow us to version the
manual in the future, though we aren't quite there yet.

The new manual [is found here](https://docs.inko-lang.org/manual/master/).

## A new network IO poller

Inko's network IO poller is now built on top of the excellent
[polling](https://crates.io/crates/polling) Rust crate. This allows us to
support a wider range of platforms in the future, and reduces the amount of code
we have to maintain ourselves.

## Fewer dependencies for building libffi

In version 0.8.0 we started using a new version of the
[libffi](https://crates.io/crates/libffi) Rust crate, reducing the number of
dependencies necessary to built the Inko VM. As the libffi changes were not yet
released, we had to use a patch to make use of these changes. A new version of
libffi has since been released, removing the need for these patches.

You can now also configure Inko to use a system installation of libffi instead
of building libffi from source. For more information, take a look at our
[Building from
source](https://docs.inko-lang.org/manual/master/getting-started/installation/#building-from-source)
guide in the manual.

## Reduced memory usage of the Ruby compiler

In commit
[fb80d4](https://gitlab.com/inko-lang/inko/-/commit/fb80d41913dd02264189901af57501bd4c4fbedb)
we reduced the memory usage of the Ruby compiler by about 20%, making it
easier to run Inko in memory constrained environments such as Docker containers.

## A new "check" option

You can now run `inko build --check` to check if an Inko program contains any
errors, without building the program. This makes it easier to integrate Inko
into your text editor/IDE of choice. For example, [we have an open pull
request](https://github.com/dense-analysis/ale/pull/3494) to add Inko support to
the popular Vim plugin ALE.

## Changes to constructing objects

Starting with Inko 0.9.0, the static method `new` is no longer defined
automatically, and the instance method `init` is no longer used to initialise an
object after its allocation. Instead, Inko objects can now be constructed
directly. For example, take this object:

```inko
object Person {
  @name: String

  def init(name: String) {
    @name = name
  }
}
```

Before version 0.9.0, you could create an instance of this object like so:

```inko
Person.new('Alice')
```

Starting with 0.9.0, you need to use the following pattern instead:

```inko
object Person {
  @name: String

  static def new(name: String) -> Self {
    Person { @name = name }
  }
}
```

Here `Person { @name = name }` creates a new instance of the `Person` object,
and sets the `@name` attribute to the `name` argument. All attributes an object
defines must be assigned when using this syntax.

Since typing the object name can get tedious, you can also use `Self` like so:

```inko
object Person {
  @name: String

  static def new(name: String) -> Self {
    Self { @name = name }
  }
}
```

Do note that the pattern `Self { ... }` is only available in static methods; it
can't be used in instance methods.

These changes bring several benefits:

* Developers have greater control over what methods are defined for their
  objects
* It's now impossible to use a partially initialised object
* The compiler no longer needs to automatically generate methods, simplifying
  the implementation
* Using variable arguments to initialise an object is now easier, as
  the `init` instance method used before didn't support variable arguments
* You can use different static methods to initialise the object in different
  ways, instead of being forced to funnel everything through a single `init`
  instance method

Various built-in types, such as `Integer` and `Array` can't be initialised using
this syntax; instead you must use the `new` static method these types define.

## Panics for the [] operator

The `[]` operator now panics whenever its used with an undefined index. This
applies to `Array.[]`, `ByteArray.[]`, and `Map.[]`. We believe this to be a
safer and better default compared to returning a nullable or `Option` type.

If you don't want a panic, you can use the `get` method these types define,
which returns an `Option` type (more on this below).

## Receiving messages with a timeout is now a separate method

The method `std::process.receive` is split into two methods: `receive` and
`receive_timeout`. This cleans up the internals a bit, and makes it more obvious
what behaviour is expected when receiving messages.

## First steps towards a self-hosting compiler

We have merged the first steps towards a self-hosting compiler. This includes
various changes to the parser, a type-checker, pattern matching support, and
various compiler changes.

Originally we had intended to merge these changes when we have a working
self-hosting compiler. Over time we realised there is still a lot of work to do,
and keeping multiple branches in sync (with lots of changes between these
branches) is a challenge. To make development easier, we have merged what we
have so far.

The self-hosting code merged so far is still a work in progress. For example,
it's not yet able to infer closure argument types. We will continue development
on the self-hosting compiler in the coming months.

In spite of being a work in progress, the work has proven invaluable; even
revealing several soundness issues the Ruby compiler failed to detect.

## Nullable types are replaced with an Option type

Inko used nullable types (technically "nillable" as Inko used `Nil` instead of
`NULL`) for optional values. In 0.9.0 this has been replaced with the use of an
`Option` type.

While nullable types may seem like a good solution, they are difficult to
support without running into soundness issues. For example, the following code
used to compile but result in a runtime error:

```inko
def add(numbers: Array!(?Integer)) {
  numbers.push(Nil)
}

let numbers: Array!(Integer) = Array.new(10)

add(numbers)

numbers[1] + 5 # This will error, because it's Nil instead of an integer
```

This would compile as `Integer` is compatible with `?Integer`, and error because
our code isn't expecting the Array to contain a `Nil`.

Nullable also require more work from the user when dealing with output that may
be explicitly set to `Nil`. For example, using iterators required the use of two
methods: one to check if a new value is available, and one to get the value.

Lastly, nullable types make composition difficult. For example, we can't define
a generic `map` method for all nullable types in Inko, as a `?T` and a `T` are
the same types at runtime (assuming the `?T` is not `Nil`).

Using an `Option` type solves these problems, as `Option!(T)` and `T` are
fundamentally different types, both which exist at runtime.

For these reasons, nullable types have been removed in Inko 0.9.0 and replaced
with the use of an `Option` type. To make working with these types easier, you
can use `?T` to signal an optional `T`. This is just syntax sugar for
`Option!(T)`, but cuts down the amount of times you have to type the word
"Option" in your code.

The introduction of an `Option` type also makes it easier to write iterators, as
we no longer need two methods to use an iterator. Instead, iterators now define
a `next` method that returns an `Option!(T)`, with a `None` value signalling the
end of the iterator.

`Nil` still exists, but is only used in cases where it makes sense (e.g. when a
method omits its return type).

## Writing iterators using generators

Inko now supports generators, drastically simplifying the process of writing
iterators. Generators are limited to methods, and require you to annotate the
method with the type that it yields. Generators also implement the `Iterator`
trait, allowing you to use them as regular iterators.

As an example, we can define an `Integer` generator like so:

```inko
def generator => Integer {
  yield 10
  yield 20
}

let gen = generator

gen.next # => Option(10)
gen.next # => Option(20)
gen.next # => None
```

Here `yield` yields a value, then continues where it left off when the generator
is resumed.

Combined with the introduction of `Option` types, this makes writing external
iterators a breeze. For example, this is how `Map.iter` is implemented in Inko
0.8.1:

```inko
def iter -> Iterator!(Pair!(K, V)) {
  let mut index = 0
  let mut found: ?Pair!(K, V) = Nil
  let max = @buckets.length

  Enumerator.new(
    while: {
      {
        (index < max).and { found.nil? }
      }.while_true {
        found = @buckets[index]
        index += 1
      }

      found != Nil
    },
    yield: {
      let pair = found!

      found = Nil

      pair
    }
  )
}
```

And here is the implementation for version 0.9.0:

```inko
def iter => Pair!(K, V) {
  @buckets.each do (pair_opt) {
    pair_opt.let do (pair) { yield pair }
  }
}
```

That's a big difference!

## Pattern matching is now available

Pattern matching has been covered in previous articles, and is available in Inko
0.9.0. You can read up all about it in the new [Pattern
matching](https://docs.inko-lang.org/manual/master/getting-started/pattern-matching/)
manual.

## Object is now a trait

While Inko didn't expose inheritance through the language/syntax, it relied on
it internally as all objects were an instance of `Object`. In Inko 0.9.0,
`Object` is now a trait that is implemented automatically for instances of
user-defined objects. The `Any` trait has been turned into a compile-time only
type, much like the `Never` type. This type can't be used for much on its own,
and instead must be casted or pattern-matched into a more useful type.

An important detail is that the `Object` trait is _only_ implemented for
instances of user-defined objects. It's _not_ implemented for types such as
traits and modules. This means the following is not valid:

```inko
object Person {}

# invalid because Person itself doesn't implement Object
Person.if_true { ... }
```

But this is valid, because an instance of `Person` _does_ implement the `Object`
trait:

```inko
Person {}.if_true { ... }
```

These changes mean inheritance is no longer relied upon. This allows us to work
towards a more efficient memory representation of objects, and more efficient
(and simpler) method lookups.

As part of these changes, the `Hash` and `Equal` traits are no longer
implemented automatically.

## Importing methods from modules

You can now import individual methods from a module:

```inko
# module foo.inko
def foo -> Integer {
  42
}

# module bar.inko
import foo::(foo)

foo # => 42
```

Importing methods requires the use of parentheses (just as is necessary when
importing multiple symbols), as the compiler otherwise thinks it has to import
the _module_ `foo::foo`. This restriction may be lifted in the future.

## Loop methods are now in a separate module

Loop methods such as `loop` and `while_true` are no longer defined on the
`Block` type, as this leads to soundness issues. For example, in Inko 0.8.1 this
code would type-check:

```inko
do (number) { number > 10 }.while_true { foo }
```

This is unsound because the implementation of `while_true` never passes any
arguments to its receiver, resulting in a runtime error.

This can't be solved without making the type system overly complex. To work
around that, we introduce a new module for loops: `std::loop`. This module
defines three methods: `while`, `loop`, and `repeat`. As `while` and `loop` are
commonly used, these are exposed using the prelude, removing the need to import
them manually.

This all combined means you now write loops as follows:

```inko
import std::stdio::stdout

let mut i = 0

while({ i < 10 }) {
  stdout.print(i)
  i += 1
}
```

## Garbage collection in process threads

Garbage collection is now performed in the same thread that was running the
process before triggering garbage collection, instead of a separate thread being
used. This reduces the garbage collection time as we no longer need to move data
across threads, reduces the total number of threads necessary, and simplifies
the garbage collection implementation. Parallel tracing is still performed using
a pool of threads.

## Documentation fixes

[Matheus Richard](https://gitlab.com/MatheusRich)
[fixed](https://gitlab.com/inko-lang/inko/-/merge_requests/118)
[several](https://gitlab.com/inko-lang/inko/-/merge_requests/117)
[typos](https://gitlab.com/inko-lang/inko/-/merge_requests/119) in our
documentation. Thanks Matheus!

## Other changes

There are lots of other changes included in this release, so be sure to check
out [the changelog][changelog] for this release.

If you'd like to follow the development of Inko, consider joining our [Matrix
chat room](https://matrix.to/#/+inko:matrix.org) or our [Reddit
community](https://www.reddit.com/r/inko/).

[changelog]: https://gitlab.com/inko-lang/inko/-/blob/5dd2dabb08f6efc9e852a9f26591582ae85cba5d/CHANGELOG.md#090-december-23-2020
