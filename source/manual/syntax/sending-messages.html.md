---
title: Sending messages
---

Syntax:

```ebnf
expression = ? Any valid Inko expression ?;
send       = [ expression, '.' ], identifier, [ type-args ], send-args;
type-args  = '!(', type, { ',', type } ')';
send-args  = [ '(' ], [ expression, { ',', expression } ], [ ')' ];
```

Sending messages can be done in one of two ways: with or without a receiver,
followed by an optional list of arguments to pass. When no receiver and
arguments are given, a message send is parsed as an identifier, and it's up to
the compiler to figure out if that translates to a method call or not.

When a receiver is given, multiple messages can be chained together, each being
sent to the result of the previous expression.

When sending a message, explicit type arguments can be provided. If provided,
the expression should always be treated as a message send, even if a local
variable is defined with the same name as the message.

Parenthesis can be left out. When these are left out, the arguments list
continues until the last expression that does not end with a comma (`,`). If no
parenthesis are provided, the first argument _must_ come on the same line as the
message. If not, then the argument is treated as a separate expression.

## Examples

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
greet 'Hello', 'Alice'
person.greet 'Hello', 'Alice'
```

Passing type arguments:

```inko
spawn!(Integer)
process.spawn!(Integer)
```
