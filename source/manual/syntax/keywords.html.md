---
title: Keywords
---
<!-- vale off -->

Syntax:

```ebnf
keyword = 'as'   | 'do'  | 'else'   | 'for'    | 'impl' | 'import' | 'lambda'
        | 'let'  | 'mut' | 'object' | 'return' | 'self' | 'throw'  | 'trait'
        | 'try!' | 'try' | 'where'  | 'def';

return = 'return', [ expression ]
throw  = 'throw', expression;
```

Except for the `try!` keyword, all keywords can be used as method and message
names. When using them for message names, an explicit receiver is required. For
example:

```inko
def lambda -> Integer {
  10
}

self.lambda # => 10
```

Some keywords take arguments, such as the `return` and `throw` keywords.
