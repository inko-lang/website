---
title: Imports
---
<!-- vale off -->

Syntax:

```ebnf
import  = 'import', identifier, { '::', identifier }, [ symbols ];
symbols = '::(', symbol, { ',', symbol }, ')';
symbol  = 'self' | constant, [ 'as', constant ];
```

Imports start with the `import` keyword, and are followed by at least one
identifier. Sub modules are separated using `::`, and the list of symbols to
import (if any) is defined using `::(symbol, symbol, ...)`. Symbols can be
aliased using `original as alias`. `self` can be used in the list of symbols to
import to refer to the module itself, allowing you to import the module itself
along with any additional symbols.

## Examples

Importing a module:

```inko
import std::fs
```

Importing a module and aliasing it:

```inko
import std::fs::(self, Foo)
```

Importing multiple symbols:

```inko
import std::thing::(Foo, Bar, Baz)
```

Importing multiple symbols, and aliasing some:

```inko
import std::thing::(Foo, Bar as Baz)
```
