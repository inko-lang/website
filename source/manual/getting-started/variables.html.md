---
title: Variables
---
<!-- vale off -->

There are three types of variables that can be defined:

1. Local variables
1. Instance attributes
1. Constants

Local variables and constants are defined using the `let` keyword. Instance
attributes are defined in an object body, and assigned in its `init` method.

Local variables start with a lowercased letter, constants start with a capital
letter. You can also prefix them with an underscore, which may be used to ignore
warnings for unused variables.

Variables can not be reassigned by default. To allow this, define a variable
using `let mut` instead:

```inko
let mut number = 10

number = 5
```

Constants can never be reassigned, meaning the following is invalid:

```inko
let mut Number = 10
```

The type of a variable is inferred from the value that is assigned. However, it
is possible to specify a custom type, as long as the value assigned is
compatible with it:

```inko
let number: Integer = 01
```
