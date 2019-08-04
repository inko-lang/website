---
title: Reassignments
---
<!-- vale off -->

Syntax:

```ebnf
expression   = ? Any valid Inko expression ?;
reassignment = ( identifier | attribute ), '=', expression;
```

Reassignment expressions can be used to reassign the value of a local variable
or attribute. Constants can not be reassigned.
