---
title: Syntax
---

Inko's syntax is straightforward. This section describes the various aspects of
the syntax. This section is meant for developers to better understand the Inko
syntax. This section is _not_ an official grammar and might be slightly out of
date from time to time.

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Encoding

All Inko source files must be UTF-8 encoded, even though Inko's own syntax only
uses characters in the ASCII range.

## Keywords

The following identifiers are treated as keywords:

* `as`
* `def`
* `do`
* `else`
* `for`
* `impl`
* `import`
* `lambda`
* `let`
* `mut`
* `object`
* `return`
* `self`
* `static`
* `throw`
* `trait`
* `try`
* `where`

Except for the `try!` keyword, all keywords are available as method and message
names. When using a keyword as a message, an explicit receiver is required:

```inko
def lambda -> Integer {
  10
}

self.lambda # => 10
```

Some keywords take arguments, such as the `return` and `throw` keywords:

```inko
return 10
throw 'oh no!'
```

## Identifiers

Identifiers are sequences of Unicode characters or digits, starting with
either:

1. A letter in the range `a-z`, followed by zero or more non special characters.
1. An underscore (`_`), followed by at least one non special character.

Some examples:

* `foo`
* `_foo`
* `foo123`
* `_foo123`
* `foo_bar`

If an identifier starts with `::`, then it's treated as a reference to a module
global variable.

## Instance attributes

Instance attributes start with a `@`, followed by everything that is valid for
an identifier.

Some examples:

1. `@foo`
1. `@_foo`
1. `@foo123`
1. `@_foo123`
1. `@foo_bar`

## Comments

Comments are created using `#`, and run until the end of the line:

```inko
# This is a comment
```

Multiple lines starting with the same kind of comment, without any leading
characters, should be treated as a single comment. For example, this is a single
comment:

```inko
# This is the first line of the comment.
# This is the second line of the comment.
```

Here both lines are treated as a single comment. Empty lines between comments
are ignored, meaning the following is still treated as a single comment:

```inko
# This is the first line of the comment.

# This is the second line of the comment.
```

The following example shows two separate comments:

```inko
# This is the first comment.
10 # This is a second, separate comment.
```

## Constants and types

Constants are sequences of Unicode characters or digits, starting with a
character in the range `A-Z`. Constants can be looked up relative to other
constants by using `::`.

Some examples:

* `Foo`
* `Foo_Bar`
* `FooBar123`
* `Foo::Bar`: this looks up `Bar` in `Foo`

Type names are constants, optionally followed by a list of type arguments. Some
examples:

* `Foo!(A)`
* `Foo_Bar!(A, B)`
* `FooBar123!(A, B)`
* `Foo::Bar!(A, B)`

## Variable bindings

The `let` keyword is used to bind the result of an expression to a constant or
variable. The binding can is made mutable by using `let mut` instead of just
`let`. You can not use `let mut` when defining a constant, as constants can not
be reassigned.

Using `let` for attributes, such as `let @foo = 10` is not valid.

## Literals

The following types of literals are available:

1. Integers
1. Floats
1. Strings
1. Methods
1. Blocks
1. Lambdas
1. Ranges
1. Objects
1. Traits
1. Implementations

### Integers

Integers come in two forms: decimal and hexadecimal. Digits can be separated
using an underscore.

Examples:

* `10`
* `100_000`
* `0xfff`

### Floats

Floating point literals come in two forms:

1. A decimal literal followed by a period character (`.`), followed by another
   decimal literal. Optionally followed by an exponent.
1. A decimal literal followed by an exponent.

Exponents come in one of two forms (here `10` is just an example number):

* `e10` or `E10`
* `e+10` or `E+10`

### Strings

Strings use either single or double quotes, but never a mix of the two. Double
quoted strings can contain the following escape sequences:

* `\n`
* `\r`
* `\e`
* `\t`

### Methods

Methods are defined using the `def` keyword, followed by the name, followed by
the header. The header starts with an optional list of type arguments, followed
by the method arguments, followed by the throw type, followed by the return
type, which is followed by the body. The body starts with `{` and ends with a
matching `}`.

Examples:

* `def foo { 10 }`
* `def foo(number) { 10 }`
* `def foo(number: Integer) { 10 }`
* `def foo(number: Integer) -> Integer { 10 }`

You can also define a static method using the `static` keyword:

* `static def foo { 10 }`
* `static def foo(number) { 10 }`
* `static def foo(number: Integer) { 10 }`
* `static def foo(number: Integer) -> Integer { 10 }`

### Blocks and lambdas

Blocks and lambas share the exact same syntax, with the only difference being
the starting keyword: `do` for blocks, and `lambda` for lambdas. The rest of the
syntax is the same as the syntax for defining methods.

The `do` keyword is optional for blocks, but is required when you want to define
the arguments, throw type, or return type. Lambdas always have to start with the
`lambda` keyword.

Examples:

* `{ 10 }`
* `do { 10 }`
* `do -> Integer { 10 }`
* `do (number) { number }`
* `do !! Integer -> Integer { number }`
* `lambda { 10 }`
* `lambda -> Integer { 10 }`
* `lambda (number) { number }`
* `lambda !! Integer -> Integer { number }`

### Objects

Objects are defined using the `object` keyword, followed by the name of the
object. The object body starts with a `{` and ends with a matching `}`. Example:

```inko
object Person {
  # ...
}
```

### Traits

Traits are defined using the `trait` keyword, followed by the name of the trait,
and an optional list of traits that are required to be implemented first. The
trait body starts with a `{` and ends with a matching `}`. Example:

```inko
trait Inspect: ToString {
  # ...
}
```

### Implementations

Trait implementations start with the `impl` keyword, followed by the name of the
trait to implement, followed by `for`, which is then followed by the type name
to implement the trait for. The body of the implementation starts with
a `{` and ends with a matching `}`. Example:

```inko
impl ToString for Person {
  # ...
}
```

## Binary expressions

Binary expressions are expression in the form `expression OPERATOR expression`,
such as `10 + 5` and `10..20`. Binary expressions are parsed into message sends,
so `10 + 5` is translated into `10.+(5)`.

Parsing of binary expressions is left-associative. This means that this:

```inko
1 * 2 + 3 - 4
```

Is parsed as:

```inko
((1 * 2) + 3) - 4
```

## Sending messages

Sending messages can is done in one of two ways: with or without a receiver,
followed by an optional list of arguments to pass. When no receiver and
arguments are specified, a message send is parsed as an identifier, and it's up
to the compiler to figure out if that translates to a method call or not.

When a receiver is given, multiple messages can be chained together, each is
sent to the result of the previous expression.

When sending a message, explicit type arguments can be provided. If provided,
the expression should always be treated as a message send, even if a local
variable is defined with the same name as the message.

Parentheses can be omitted out if:

1. No arguments are provided.
2. The only argument provided is a closure or lambda.

If the last argument is a closure or lambda, it can be passed outside of the
parentheses. In this case it will be treated as if it were the last argument
inside the parentheses.

Sending a message without any arguments:

```inko
greet
```

Sending a message using a receiver:

```inko
person.greet
```

Chaining multiple messages:

```inko
person.greet.twice.in_english
```

Passing arguments:

```inko
greet('Hello', 'Alice')
person.greet('Hello', 'Alice')
```

Passing arguments, without parenthesis:

```inko
greet { 'hello' }
person.greet { 'hello' }
```

Passing type arguments:

```inko
spawn!(Integer)
process.spawn!(Integer)
```

## Reassignments

Reassignment expressions are used to reassign the value of a local variable or
attribute:

```inko
number = 20
@number = 20
```

Constants can not be reassigned:

```inko
# This will produce a syntax error.
NUMBER = 20
```

## Slicing

Slice expressions are used to access to set the index of an object. These are
written in the form `receiver[index]` and `receiver[index] = value`. These
expressions are parsed into method calls, with `receiver[index]` translating to
`receiver.[](index)`, and `receiver[index] = value` translating to
`receiver.[]=(index, value)`.

## Try expressions

`try` and `try!` are used for error handling. `try` supports an optional `else`
block, `try!` does not. The `else` block takes an optional single argument,
enclosed in parenthesis.

The `try`, `try!`, and `else` expressions can be enclosed in `{` and `}`, but
this is optional. The `try` and `try!` bodies can only contain a single
expression, whereas the `else` body can contain multiple expressions.

## Imports

Imports start with the `import` keyword, and are followed by at least one
identifier. Sub modules are separated using `::`, and the list of symbols to
import (if any) is defined using `::(symbol, symbol, ...)`. Symbols can be
aliased using `original as alias`. You can use `self` in the list of symbols to
import to refer to the module itself, allowing you to import the module itself
along with any symbols.

Importing a module:

```inko
import std::fs
```

Importing a module and aliasing it:

```inko
import std::fs::(self, Foo)
```

Importing multiple symbols:

```inko
import std::thing::(Foo, Bar, Baz)
```

Importing multiple symbols, and aliasing some:

```inko
import std::thing::(Foo, Bar as Baz)
```
