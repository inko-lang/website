---
title: Identifiers
---
<!-- vale off -->

Syntax:

```ebnf
(* A char is any single Unicode charater, such as "a" or "-" *)
char = ? any unicode character ?;

special = '!' | '@' | '#'  | '$'  | '%' | '^' | '&' | '*' | '(' | ')' | '-'
        | '+' | '=' | '\'  | ':'  | ';' | '"' | "'" | '<' | '>' | '/' | ','
        | '.' | ' ' | "\r" | "\n" | '|' | '[' | ']';

digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9';

lower = 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'g' | 'h' | 'i' | 'j' | 'k' | 'l'
      | 'm' | 'n' | 'o' | 'p' | 'q' | 'r' | 's' | 't' | 'u' | 'v' | 'w' | 'x'
      | 'y' | 'z';

word       = ( char - special | digit | '_' );
identifier = ( '_', word | lower ) { word };
global     = '::' identifier;
```

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

If an identifier starts with `::`, then it is treated as a reference to a module
global variable.
