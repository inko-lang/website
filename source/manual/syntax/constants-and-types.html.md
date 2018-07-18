---
title: Constants and types
---

Syntax:

```ebnf
(* A char is any single Unicode charater, such as "a" or "-" *)
char = ? any unicode character ?;

special = '!' | '@' | '#'  | '$'  | '%' | '^' | '&' | '*' | '(' | ')' | '-'
        | '+' | '=' | '\'  | ':'  | ';' | '"' | "'" | '<' | '>' | '/' | ','
        | '.' | ' ' | "\r" | "\n" | '|' | '[' | ']';

digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9';

upper = 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'H' | 'I' | 'J' | 'K' | 'L'
      | 'M' | 'N' | 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' | 'U' | 'V' | 'W' | 'X'
      | 'Y' | 'Z';

word     = ( char - special | digit | '_' );
constant = upper, { word }, [ '::', constant ];

type           = constant, '!(', type-arguments, ')';
type-arguments = type { ',', type };
```

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
