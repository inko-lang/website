---
title: Compiler directives
---
<!-- vale off -->

Syntax:

```ebnf
directive      = '![', directive-pair ']';
directive-pair = identifier, ':', identifier;
```

Compiler directives are used to set certain configuration options for the
compiler. Directives can only occur at the top level of a module. For example:

```inko
![define_module: false]
```
