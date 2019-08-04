---
title: Try
---
<!-- vale off -->

Syntax:

```ebnf
expression = ? Any valid Inko expression ?;
try        = try-else | try-bang;
try-else   = 'try', [ '{' ], expression, [ '}' ], [ else ];
try-bang   = 'try!', [ '{' ], expression, [ '}' ], [ else ];
else       = 'else', [ '(', identifier, ')' ], [ '{' ], { expression }, [ '}' ];
```

`try` and `try!` are used for error handling. `try` supports an optional `else`
block, `try!` does not. The `else` block takes an optional single argument,
enclosed in parenthesis.

The `try`, `try!`, and `else` expressions can be enclosed in `{` and `}`, but
this is optional. The `try` and `try!` bodies can only contain a single
expression, whereas the `else` body can contain multiple expressions.
