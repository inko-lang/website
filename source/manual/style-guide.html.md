---
title: Style guide
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

This guide documents the best practises to follow when writing Inko source code,
such as what indentation method to use, and when to use keyword arguments.

## Encoding

Inko source files should be encoded in UTF-8.

## Line endings

Unix (`\n`) line endings should be used at all times.

## Line length

Lines should be hard wrapped at 80 characters per line. It's OK if a line is a
few characters longer, but only if wrapping it makes it less readable.

## Indentation

Inko source code should be indented using 2 spaces per indentation level, not
tabs. Tabs are displayed inconsistently across different mediums, potentially
making source code harder to read. By using spaces _only_ we also prevent the
accidental mixing of tabs and spaces.

Inko relies heavily on blocks, which can lead to many indentation levels. Using
4 spaces per indentation level would consume too much horizontal space, so we
use 2 spaces instead.

Opening curly braces are placed on the same line as the expression that precedes
it:

```inko
# Good
[10, 20, 30].each do (number) {

}

# Bad
[10, 20, 30].each do (number)
{

}
```

## Naming

Constants use PascalCase for naming, such as `ByteArray` and `String`:

```inko
# Good
object AddressFormatter {}

# Bad
object Addressformatter {}
```

Methods, local variables, instance variables, and arguments all use snake_case
for naming, such as `to_string` and `write_bytes`:

```inko
# Methods

# Good
def to_string {}

# Bad
def toString {}

# Arguments

# Good
def write_bytes(bytes) {}

# Bad: "val" is not a meaningful name.
def write_bytes(val) {}

# Variables

# Good
let home_address = 'Foo Street'
let @home_address = 'Foo Street'

# Bad
let homeAddress = 'Foo Street'
let @homeAddress = 'Foo Street'
```

### Let constants

Constants defined using `let` use SCREAMING_SNAKE_CASE, such as `DAY_OF_WEEK` or
`NUMBER`:

```inko
# Good
let FIRST_DAY_OF_WEEK = 'Monday'

# Bad
let FirstDayOfWeek = 'Monday'
```

### Argument names

Arguments should use human readable names, such as `address`. Avoid the use of
abbreviations such as `num` instead of `number`. Every argument is a keyword
argument, and the use of abbreviations can make it harder for a reader to figure
out what the meaning of an argument is.

### Predicates

When defining a method that returns a `Boolean`, end the method name with a `?`:

```inko
# Good
def allowed? -> Boolean {
  # ...
}

# Bad
def allowed -> Boolean {
  # ...
}
```

This removes the need for prefixing your method names with `is_`, such as
`is_allowed`.

### Traits

Traits should be a given a clear name such as `ToArray` or `Index`. Don't use
the pattern of `[verb]-ble` such as `Enumerable` or `Iterable`.

### Conversion methods

Methods that convert one type into another should be prefixed with `to_`,
followed by a short name of the type. Examples include `to_array`, `to_string`,
`to_coordinates`, etc.

## Parenthesis

Inko allows you to omit parenthesis when sending a message. When sending a
message without arguments, leave out the parenthesis:

```inko
# Good
[10, 20, 30].first

# Bad
[10, 20, 30].first()
```

When passing one or more arguments, include parenthesis:

```inko
# Good
'hello'.slice(0, 1)

# Bad
'hello'.slice 0, 1
```

If the last argument is a block, leave out the parenthesis:

```inko
# Good
test.group 'This is a test group', do (g) {

}

# Bad
test.group('This is a test group', do (g) {

})
```

When the number of arguments don't fit on a single line, place every argument on
their own line like so:

```inko
some_object.some_message_name(
  10,
  20,
  30
)
```

The use of a trailing comma for the last argument should be avoided.

## Message chains

When chaining multiple messages together that don't fit on a single line,
place every message on a separate line:

```inko
foo
  .bar
  .baz
```

## Binary expressions

When sending a message to the _result_ of a binary expression, place the message
on the next line and indent it with two space:

```inko
# Bad
(10 > 5).if_true {
  # ...
}

# Good
10 > 5
  .if_true {
    # ...
  }
```

Inko will parse both examples the same way, but the second example saves us from
having to wrap the expression in parenthesis.

## Keyword arguments

When passing a single argument, prefer the use of positional arguments:

```inko
# Good
[10, 20, 30].remove_at(0)

# Also fine, though a bit redundant.
[10, 20, 30].remove_at(index: 0)
```

When passing multiple arguments, use keyword arguments:

```inko
# Good
'hello'.slice(start: 0, length: 2)

# Bad: we have no idea what our arguments mean.
'hello'.slice(0, 2)
```

Keyword arguments may be left out when using a DSL, such as the one provided by
`std::test`, and it's clear enough what the meaning of the arguments are:

```inko
# Good
test.group 'This is the description of the group', do (g) {

}

# Bad: the use of keyword arguments is a bit redundant here.
test.group name: 'This is the description of the group', body: do (g) {

}
```

## Comments

Comments should be used to describe intent, provide examples, and explain
certain decisions that might not be obvious to the reader. Comments should _not_
be used to explain what work is being performed.

When documenting a type, constant, or method, the first line of the comment
should be a short summary. This summary should be roughly one sentence and
describe the purpose of the item. For example:

```inko
## A Person can be used for storing details of a single person, such as their
## name and address.
object Person {

}
```

For types and methods, use `##` instead of `#`. Modules should be documented
using `#!`:

```inko
#! This is the documentation of the entire module. Just like other comments, it
#! can span multiple lines as long as every line starts with a #!

## A Person can be used for storing details of a single person, such as their
## name and address.
object Person {
  def init(name: String) {
    ## The name of the person.
    let @name = name
  }
}
```

## Imports

Imports should be placed at the top of a module, in alphabetical order _unless_
a specific order is required. If this is the case, this requirement should be
documented using a regular comment to prevent accidental reordering of the
imports:

```inko
# Good
import std::fs::file
import std::stdio::stdout

# Bad: not in alphabetical order
import std::stdio::stdout
import std::fs::file
```

The symbols imported from a module should also be listed in alphabetical order.
If `self` is imported, it should come first:

```inko
# Good
import std::fs::file::(self, FilePath)

# Bad
import std::fs::file::(FilePath, self)
```

## Modules

When defining a module, items defined in it should come in the following order:

1. Types and constants.
1. Module methods.
1. Code to run when the module is imported.

Example:

```inko
object Person {
  def init(name: String) {
    let @name = name
  }
}

def create_person(name: String) -> Person {
  Person.new(name)
}

let person = create_person('Alice')
```

You can deviate from this guideline if a different order is required.

## Blocks

When a closure does not take any arguments, leave out the `do` keyword:

```inko
# Good
let block = { 10 }

# Bad: `do` is redundant
let block = do { 10 }
```

Lambdas always require the `lambda` keyword, otherwise they will be inferred as
a closure.

The `do` and `lambda` keywords should be followed by a single space:

```inko
# Good
let block = do (number) { number }

# Bad
let block = do(number) { number }
```

The return type of a block should not be specified unless required otherwise:

```inko
# Good
[10, 20, 30].each do (number) {

}

# Bad: the compiler can just infer the return type for us.
[10, 20, 30].each do (number) -> Integer {
  10
}
```

When defining a block before using it, specify the argument types _unless_ you
want them to be dynamically typed:

```inko
# Good
let block = do (number: Integer) { number }

# Technically fine if we're OK with "number" being of type Dynamic, but the
# compiler won't protect us from using the argument in the wrong way.
let block = do (number) { number }
```

## Error handling

If a try-else expression is simple enough, omit the use of curly braces:

```inko
try some_expression else do_something_else
```

If the `try` expression is complex, or the `else` body contains multiple
expressions, use curly braces for both:

```inko
try {
  some_expression
} else {
  do_something_else
  do_more_work_here
}
```

In this case `else` is placed on the same line as the closing curly brace of the
`try` expression.

If `else` argument goes on the same line as `else`:

```inko
try {
  some_expression
} else (error) {
  do_something_else
  do_more_work_here
}
```

## Implementing traits

When defining an object, it is preferred to immediately implement any desired
traits:

```inko
# Good
object Person impl ToString {}

# Bad
object Person {}

impl ToString for Person {}
```

If the `object ... impl` line is too long to fit on a single line, place every
trait name on their own line like so:

```inko
object Person impl
  Foo,
  Bar,
  Baz {

}
```

When implementing a trait for a previously defined object, use the `impl ...
for` syntax:

```inko
impl ToString for Person {

}
```
