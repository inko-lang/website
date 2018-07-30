---
title: Types
---

1. TOC
{:toc}

## Numeric types

There are two built-in numeric types in Inko: `Integer`, and `Float`. The
`Integer` type is used for arbitrarily sized (signed) integers, while `Float` is
used for IEEE 754 64 bits floating points.

## Strings

The `String` type is used for strings, such as `'hello'` and `"hello"`. Both
single and double quoted strings are of the exact same type.

Each `String` is a Unicode string, using UTF-8 as the encoding. Invalid UTF-8
sequences are replaced with the Unicode replacement sign � (U+FFFD).

## Booleans

There are two boolean types available in Inko: `True`, and `False`. Both these
objects are instances of the `Boolean` object, though you should avoid using
`Boolean` directly other than in type signature (e.g. when accepting a boolean
argument).

## Arrays and hash maps

Two collection types are available by default: `Array`, and `HashMap`. An
`Array` is used for storing a list of values of the same type. A `HashMap` is a
hash map used to map keys of type `K` to values of type `V`.

These collections can be used in type signatures like any other generic type:

```inko
def take_array_of_integers(array: Array!(Integer)) {

}

def take_hash_map_mapping_strings_to_integers(map: HashMap!(String, Integer)) {

}
```

## Byte arrays

Byte arrays efficiently store a sequence of bytes. Byte arrays require an
explicit import before you can use them:

```inko
import std::byte_array::ByteArray
```

Once imported, the `ByteArray` type can be used in a type signature like any
other type:

```inko
import std::byte_array::ByteArray

def bytes_to_string(bytes: ByteArray) {
  # ...
}
```

## Nil

`Nil` is a type used to represent the absence of a value. A `Nil` responds to
any message, returning `Nil` itself. For some messages there is a custom
implementation, in which case the return type may be something other than `Nil`.

## Optional types

Optional types are types that can either be a particular type, or `Nil`. These
types are created using the syntax `?T`, where `T` is the type. For example, to
define an optional `Integer` you would use `?Integer`:

```inko
def take_integer_or_nil(value: ?Integer) {
  ...
}
```

## Block types

A `Block` is a method, closure, or lambda. For type signatures you can use `do`
to refer to a closure, or `lambda` to refer to a lambda:

```inko
def take_closure(block: do) {

}

def take_lambda(block: lambda) {

}
```

A `lambda` type can be passed to a `closure` type, but not the other way around.
When using `do` or `lambda` you can also specify the arguments, throw type, and
return type:

```inko
def take_closure(block: do (Integer) !! SomeErrorType -> Integer) {

}
```

To accept a `Block` of any kind, just use `Block` in the type signature:

```inko
def take_any_block(block: Block) {

}
```

When using `Block` in the type signature, you can not specify any argument
types, throw types, or return types.

## Object types

Pretty much everything in Inko is an object, including the types mentioned
above. Custom objects can be created using the `object` keyword:

```inko
object Person {

}

Person.new
```

## Dynamic types

The `Dynamic` type is a special type that only exists at compile time. When
something is `Dynamic`, any other type can be passed to it. When defining
methods you can simply leave out the argument types or return type, and they
will be inferred as `Dynamic`:

```inko
def take_dynamic_value(value) {

}
```

For `let` expressions you must define the type explicitly, because by default
the type of a `let` binding is inferred based on the value:

```inko
let dynamic_value: Dynamic = 10
```

For closures and lambdas, the arguments will default to `Dynamic` _only_ if the
closure or lambda is not directly passed as an argument:

```inko
let block = do (number) { number }

some_method(block)
```

Here the `number` argument is inferred as `Dynamic`, because the compiler does
not know what type to use when type checking the block. When passing the block
directly, the compiler _can_ infer this:

```inko
def some_method(block: do (Integer)) {

}

some_method do (number) { number }
```

Here the `number` argument is inferred as an `Integer`.

## Self types

The type `Self` can be used in a method in an object or trait to refer to the
object that implements the method:

```inko
object Person {
  def take_person(person: Self) {

  }
}
```

The `Self` type is currently evaluated upon definition, and not upon being
referenced. [This is likely to change in the future](https://gitlab.com/inko-lang/inko/issues/107).

## Void types

The type `Void` is used to signal the compiler that an expression will never
return. Direct use of this type is heavily discouraged. A value of type `Void`
can be passed to any other type, since during runtime this will never truly
happen (because a `Void` expression can not return). The inverse (passing `T` to
a `Void`) is not possible.
