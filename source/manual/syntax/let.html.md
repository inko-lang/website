---
title: Let
---
<!-- vale off -->

Syntax:

```ebnf
expression = ? Any valid Inko expression ?;
let        = let-local | let-attr | let-const;
let-local  = 'let', [ 'mut' ], identifier, [ let-type ], '=', expression;
let-attr   = 'let', [ 'mut' ], attribute, [ let-type ], '=', expression;
let-const  = 'let', constant, [ let-type ], '=', expression;
let-type   = ':', type;
```

The `let` keyword is used to bind the result of an expression to a constant or
variable. The binding can be made mutable by using `let mut` instead of just
`let`. You can not use `let mut` when defining a constant, as constants can not
be reassigned.
