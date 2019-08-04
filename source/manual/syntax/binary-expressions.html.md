---
title: Binary expressions
---
<!-- vale off -->

Syntax:

```ebnf
expression = ? Any valid Inko expression ?;
binary     = expression, operator, expression, { operator, expression };
operator   = '||' | '&&' | '==' | '!=' | '<' | '<=' | '>' | '>=' | '|' | '&'
           | '^'  | '&'  | '<<' | '>>' | '+' | '-'  | '/' | '%'  | '*' | '**'
           | '..' | '...';
```

Binary expressions are expression in the form `expression OPERATOR expression`,
such as `10 + 5` and `10..20`. Binary expressions are parsed into message sends,
so `10 + 5` is translated into `10.+(5)`.

All binary expressions are left associative. This means that this:

```inko
1 * 2 + 3 - 4
```

Is parsed as:

```inko
((1 * 2) + 3) - 4
```
