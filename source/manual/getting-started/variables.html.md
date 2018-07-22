---
title: Variables
---

There are three types of variables that can be defined:

1. Local variables
1. Instance attributes
1. Constants

These variables are defined using the `let` keyword:

```inko
let local_variable = 10
let @instance_attribute = 10
let Constant = 10
```

Constants start with a capital letter.

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
