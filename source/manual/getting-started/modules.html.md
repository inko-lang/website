---
title: Modules
---

A module is a namespace, isolated from other modules. Modules can define
methods, types, or run code directly. Modules can be defined as children of
other modules, in which case you refer to them using the syntax
`parent_module::child_module`.

Every Inko source file is automatically a module, meaning you don't need to do
anything special to create a module. For source files, the name of the module is
based on the path to the module, relative to the project directory. Every file
path separator (a `/` on Unix systems) is replaced with `::`. For example, a
module located in `src/myproject/foo.inko` is called `myproject::foo`. Currently
there is no official way of defining modules that are not tied to a source file,
but this may be supported in the future.

The methods and types in a module are always public, and there is no way to
declare these as private. If your module relies on certain types or methods that
you don't want to expose as part of the public API, moving these types and/or
methods to a separate module is usually the best solution. For example, the
module `std::fs::file` relies on various internals provided by the module
`std::fs::raw`.

Inside a module scope, `self` refers to the module itself:

```inko
self # => this will return a module object.
```

We can use the `ThisModule` constant to refer to the module object anywhere
inside the module, even in methods and other types:

```inko
self # => the current module

def example {
  ThisModule # => the current module
}

object Person {
  def example {
    ThisModule # => the current module
  }
}
```

This can be useful if we want to send a message to the module, but the lack of a
receiver would conflict:

```inko
def example -> Integer {
  10
}

object Example {
  def example -> Integer {
    # If we just send "example" here we would recurse into this method,
    # overflowing the stack. We can use "ThisModule.example" in this case to
    # work around this.
    ThisModule.example
  }
}
```

## Imports

A module on its own is not very useful. Fortunately, one module can import
resources from another module, optionally binding them to a different name.
Imports can only occur at the top-level of a module, and inside something else
such as a method or type.

To import a constant or method, we use the `import` keyword like so:

```inko
import std::fs::file
```

Here we imported the module `std::fs::file`, and don't specify any symbols to
import. This will result in the module itself being imported, and the module
will be bound to the name `file` in the importing module:

```inko
import std::fs::file

file # => std::fs::file
```

We can import a specific symbol like so:

```inko
import std::fs::file::(ReadOnlyFile)
```

Here we only import the `ReadOnlyFile` constant, exposing it as a constant with
the same name. We can also import multiple constants:

```inko
import std::fs::file::(ReadOnlyFile, WriteOnlyFile)
```

We can also give them a different name:

```inko
import std::fs::file::(ReadOnlyFile as File)

File # => ReadOnlyFile
```

We can use `self` to refer to the module that we are importing symbols from:

```inko
import std::fs::file::(self, ReadOnlyFile)

file         # => std::fs::file
ReadOnlyFile # => ReadOnlyFile
```

Importing methods work a little bit differently. We can't directly import a
method, instead we have to import the module then use it as the receiver when
sending messages:

```inko
import std::fs::file

file.read_only('README.md')
```

Imports are always processed before executing any code in a module, even when
code is placed before an import. This means that this:

```inko
import std::stdio::stdout

stdout.print('hello')

import std::fs::file
```

Is executed as follows:

```inko
import std::stdio::stdout
import std::fs::file

stdout.print('hello')
```

When importing a symbol that already exists, an error will be produced by the
compiler.

## Module variables

Module variables are variables that look like local variables, but are available
in any scope inside the module. Symbols imported from another module are all
defined as module variables in the importing module, allowing you to use them
anywhere.

Any constant defined at the top-level of a module is automatically also a module
variable:

```inko
let NUMBER = 10

object Person {
  def number -> Integer {
    NUMBER
  }
}

Person.new.number # => 10
```

When assigning a value to a module variable, the variable will be assigned a
_copy_ of the value. This is because module variables are stored on a separate
heap, instead of a process' local heap.
