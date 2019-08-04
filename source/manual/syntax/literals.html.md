---
title: Literals
---
<!-- vale off -->

Syntax:

```ebnf
any        = ? Any character ?;
expression = ? Any valid Inko expression, such as 1 + 1 ?;

literal = integer | float | string | block | lambda | array | hash_map;
digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9';

(* Integers *)
integer     = dec-integer | hex-integer;
dec-integer = digit, { digit }, [ '_', digit, { digit } ];
hex-integer = '0x', hex_digit, { hex_digit };
hex_digit   = digit | 'a' | 'b' | 'c' | 'd' | 'e' | 'f'
                    | 'A' | 'B' | 'C' | 'D' | 'E' | 'F'

(* Floats *)
float = dec-integer, '.', dec-integer, [ float-exponent ]
      | dec-integer, float-exponent;

float-exponent = ( 'e' | 'E' ), [ '+' ], digit, { digit };

(* Strings *)
string        = single-string | double-string;
single-string = "'", { any - "'" | "\'" }, "'";
double-string = '"', { any - '"'' | '\"' }, '"'';

(* Methods *)
method = 'def', identifier, [ block-header ], block-body;

(* Blocks *)
block  = [ 'do', [ block-header ] ], block-body;
lambda = 'lambda', [ block-header ], block-body;

block-header = [ type-arguments ], [ arguments ], [ '!!', type ], [ '->', type ];
block-body   = '{', { expression }, '}';

(* Type arguments for methods, blocks, and lambdas *)
type-arguments = '!(', [ type-argument, { ',' type-argument } ] ')';
type-argument  = constant, ':', trait-list;
trait-list     = type { '+', type };

(* Arguments for methods, blocks, and lambdas *)
arguments = '(' [ argument, { ',', argument } ] ')';
argument  = identifier, [ ':', type ];

(* Arrays *)
array = '[' [ expression, { ',' expression } ] ']';

(* Hash maps *)
hash-map  = '%[' [ key-value { ',', key-value } ] ']';
key-value = expression, ':', expression;

(* Objects *)
object = 'object', type, [ 'impl', type, { ',', type } ], block-body;

(* Traits *)
trait = 'trait', type, [ ':', type, { '+', type } ], block-body;

(* Trait implementations *)
impl = 'impl', type, 'for', type, block-body;
```

The following types of literals are available:

1. Integers
1. Floats
1. Strings
1. Methods
1. Blocks
1. Lambdas
1. Arrays
1. Hash maps
1. Ranges
1. Objects
1. Traits
1. Implementations

## Integers

Integers come in two forms: decimal and hexadecimal. Digits can be separated
using an underscore.

Examples:

* `10`
* `100_000`
* `0xfff`

## Floats

Floating point literals come in two forms:

1. A decimal literal followed by a period character (`.`), followed by another
   decimal literal. Optionally followed by an exponent.
1. A decimal literal followed by an exponent.

Exponents come in one of two forms (here `10` is just an example number):

* `e10` or `E10`
* `e+10` or `E+10`

## Strings

Strings use either single or double quotes, but never a mix of the two. Double
quoted strings can contain the following escape sequences:

* `\n`
* `\r`
* `\e`
* `\t`

## Methods

Methods are defined using the `def` keyword, followed by the name, followed by
the header. The header starts with an optional list of type arguments, followed
by the method arguments, followed by the throw type, followed by the return
type, which finally is followed by the body. The body starts with `{` and ends
with a matching `}`.

Examples:

* `def foo { 10 }`
* `def foo(number) { 10 }`
* `def foo(number: Integer) { 10 }`
* `def foo(number: Integer) -> Integer { 10 }`

## Blocks and lambdas

Blocks and lambas share the exact same syntax, with the only difference being
the starting keyword: `do` for blocks, and `lambda` for lambdas. The rest of the
syntax is the same as the syntax for defining methods.

The `do` keyword is optional for blocks, but is required when you want to define
the arguments, throw type, or return type. Lambdas always have to start with the
`lambda` keyword.

Examples:

* `{ 10 }`
* `do { 10 }`
* `do -> Integer { 10 }`
* `do (number) { number }`
* `do !! Integer -> Integer { number }`
* `lambda { 10 }`
* `lambda -> Integer { 10 }`
* `lambda (number) { number }`
* `lambda !! Integer -> Integer { number }`

## Objects

Objects are defined using the `object` keyword, followed by the name of the
object. Optionally one can immediately implement a number of traits using `impl
Trait, Trait, Trait, ...`. Finally, the object body starts with a `{` and
ends with a matching `}`. Example:

```inko
object Person impl ToString {
  # ...
}
```

## Traits

Traits are defined using the `trait` keyword, followed by the name of the trait,
and an optional list of traits that are required to be implemented first. The
trait body starts with a `{` and ends with a matching `}`. Example:

```inko
trait Inspect: ToString {
  # ...
}
```

## Implementations

Standalone trait implementations start with the `impl` keyword, followed by the
name of the trait to implement, followed by `for`, which is then followed by the
type name to implement the trait for. Finally, the body of the implementation
starts with a `{` and ends with a matching `}`. Example:

```inko
impl ToString for Person {
  # ...
}
```
