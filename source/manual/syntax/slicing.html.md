---
title: Slicing
---

Syntax:

```ebnf
expression = ? Any valid Inko expression ?;
slicing    = expression, '[', expression, ']', [ '=', expression ];
```

Slice expressions are used to access to set the index of an object. These are
written in the form `receiver[index]` and `receiver[index] = value`. These
expressions are parsed into method calls, with `receiver[index]` translating to
`receiver.[](index)`, and `receiver[index] = value` translating to
`receiver.[]=(index, value)`.
