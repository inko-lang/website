---
title: Bytecode
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

IVM executes precompiled bytecode, instead of traversing some sort of AST. The
bytecode format is similar to [Three-address code][tac], although some
instructions take more than three operands.

The format in which bytecode is serialised is a fairly straightforward custom
binary format. Each Inko module is compiled into a separate bytecode file, and
each bytecode file is divided into three sections:

1. A header
1. A "compiled code" object
1. Zero or more nested compiled compiled code objects.

A "compiled code" object is a collection of instructions and meta data
describing a single Inko Block, such as a method. These objects include the
name, the path of the source file, the instructions to run, debugging
information, and more. Each compiled code object can contain 0 or more other
compiled code objects that may need to be run.

At various points in this guide will we reference certain types such as `u8` or
`i64`. These types are defined as follows:

| Type      | Meaning
|:----------|:---------------------------------------------------------------
| `u8`      | An 8 bits unsigned integer.
| `u16`     | A 16 bits unsigned integer, serialised in big-endian order.
| `u64`     | A 64 bits unsigned integer, serialised in big-endian order.
| `i64`     | A 64 bits signed integer, serialised in big-endian order.
| `[X; Y]`  | A fixed size array, containing `Y` values of type `X`, such as `[u8; 4]`.
| `boolean` | A single `u8` that can only be `0` or `1`.

In certain places we also use examples such as `[1, 2, 3]`. This means we are
referring to an array containing the values `1, 2, 3` in the given order.

## Header

Every bytecode file must start with a header. The header consists out of two
parts:

1. A signature.
1. The version of the bytecode format.

If the signature or version is not recognised, the VM will terminate with an
error.

### Signature

The signature is a `[u8; 4]` containing the following `u8` values (in order):

1. `105`
1. `110`
1. `107`
1. `111`

When converted to a string, this will read "inko".

### Version

The version is used by the VM to determine if it will be able to parse the
bytecode file. The version is a single `u8`, and is usually only incremented
when backwards incompatible bytecode changes are made. The version byte comes
directly after the signature.

The currently supported bytecode version is `2`.

## Literals

A bytecode file at times will use various literals, such as integers or strings.
These are defined using a byte that indicates the type, the length of values (if
necessary), followed by a number of bytes that make up the value. The following
literals are supported:

* Integers
* Arrays
* Byte arrays
* Big integers
* Floats
* Strings

### Integers

Integers are serialised as a `u8` of value `0`, followed by a `[u8; 8]`
containing the bytes that make up the integer. For example, the integer `42` is
serialised as:

```inko
[0, 0, 0, 0, 0, 0, 0, 0, 42]
```

The maximum value that can be serialised as an integer is
`9 223 372 036 854 775 807`.

The values are ordered in big-endian order.

### Array

Arrays are sequences of values, starting with a length. Each value is a
combination of the value type, and whatever bytes may follow it. Arrays don't
start with a certain type indicator, as they are only valid in specific places.

An array starts with a `u64` that indicates the number of values. For example,
the array `[10, 20]` is serialised as follows:

```inko
[
  0, 0, 0, 0, 0, 0, 0, 2,  # The size of the array, as an u64

  0,                       # The type marker for an i64.
  0, 0, 0, 0, 0, 0, 0, 10, # The first value, as an i64

  0,                       # The type marker for an i64.
  0, 0, 0, 0, 0, 0, 0, 20  # The second value, also an i64
]
```

### Byte arrays

Byte arrays are similar to regular arrays, except their values are always of
type `u8`. A byte array containing `[10, 20]` is serialised as follows:

```inko
[0, 0, 0, 0, 0, 0, 0, 2, 10, 20]
```

Just like regular arrays, byte arrays can only occur in specific places, hence
there is no type indicator.

Currently byte arrays are only used for big integers.

### Big integers

Big integers start with a `u8` of value `3`, followed by a byte array. For
example, the number `18 446 744 073 709 551 614` is serialised as follows:

```inko
[
  3,                                      # The type marker of a big integer.
  0, 0, 0, 0, 0, 0, 0, 16,                # The start of the bytes that make
  102, 102, 102, 102, 102, 102, 102, 102, # up the big integer.
  102, 102, 102, 102, 102, 102, 102, 101
]
```

Produces (such as a compiler) can serialise big integers as follows:

1. Convert the value to a hexadecimal string.
1. Obtain the bytes of this string, then serialise this in the form `[3,
   NUMBER-OF-BYTES, byte1, byte2, ...]`, where `NUMBER-OF-BYTES` is the number
   of bytes in the string.

### Floats

Floats are serialised as 64 bits floating points, starting with a `u8` of value
`1`, followed by a `[u8; 8]`. The float 15.2 is serialised as follows:

```inko
[
  1,                                    # The type marker of a float.
  64, 46, 102, 102, 102, 102, 102, 102  # The bytes that make up the float.
]
```

The virtual machine parses this into a float by reading the bytes, then uses
these directly as the bits layout for the float. In Rust this is done using
`std::f64::from_bits()`.

The bytes of a float are ordered in big-endian order.

### Strings

Strings start with a `u8` of value `2`, followed by a `u64` indicating the
number of _bytes_ in the string, followed by a sequence of `u8` values that make
up the string.

The string "inko" is serialised as follows:

```inko
[
  2,                      # The type indicator for a string.
  0, 0, 0, 0, 0, 0, 0, 4, # The number of bytes, as a u64.
  105, 110, 107, 111      # The bytes in the string.
]
```

## Compiled code

After the header comes a compiled code object. These objects are a bit more
complex to parse as they contain quite a bit of data. Each compiled code object
has the following fields (all of which are required), parsed in this order:

1. The name of the object, as a string.
1. The path of the source file, as a string.
1. The line number the code object originates from, as a `u16`.
1. The names of the arguments as an array of strings, empty if no arguments are
   defined.
1. A `u8` indicating the number of required arguments.
1. A `boolean` indicating if the last argument of the block is a rest argument.
1. The number of local variables used by the compiled code object, as a `u16`.
1. The number of registers used by the compiled code object, as a `u16`.
1. A `boolean` indicating if the compiled code object captures any outer local
   variables.
1. An array of 0 or more instructions.
1. An array of all the literals defined in the compiled code object. Each value
   can be of a different literal type.
1. An array of compiled code objects defined inside this compiled code object.
1. An array containing 0 or more catch entries.

## Instructions

Each VM instruction consists out of the following fields, in this order:

1. A `u8` indicating the instruction to execute.
1. An array of `u16` values, each specifying a value to pass as an argument to
   the instruction.
1. A `u16` specifying the line the instruction originates from.

The following instruction types and their `u8` values are available:

| Instruction                     | `u8` value
|:--------------------------------|:-----------
| SetLiteral                      | `0`
| SetObject                       | `1`
| SetArray                        | `2`
| GetBuiltinPrototype             | `3`
| GetTrue                         | `4`
| GetFalse                        | `5`
| SetLocal                        | `6`
| GetLocal                        | `7`
| SetBlock                        | `8`
| Return                          | `9`
| GotoIfFalse                     | `10`
| GotoIfTrue                      | `11`
| Goto                            | `12`
| RunBlock                        | `13`
| IntegerAdd                      | `14`
| IntegerDiv                      | `15`
| IntegerMul                      | `16`
| IntegerSub                      | `17`
| IntegerMod                      | `18`
| IntegerToFloat                  | `19`
| IntegerToString                 | `20`
| IntegerBitwiseAnd               | `21`
| IntegerBitwiseOr                | `22`
| IntegerBitwiseXor               | `23`
| IntegerShiftLeft                | `24`
| IntegerShiftRight               | `25`
| IntegerSmaller                  | `26`
| IntegerGreater                  | `27`
| IntegerEquals                   | `28`
| FloatAdd                        | `29`
| FloatMul                        | `30`
| FloatDiv                        | `31`
| FloatSub                        | `32`
| FloatMod                        | `33`
| FloatToInteger                  | `34`
| FloatToString                   | `35`
| FloatSmaller                    | `36`
| FloatGreater                    | `37`
| FloatEquals                     | `38`
| ArraySet                        | `39`
| ArrayAt                         | `40`
| ArrayRemove                     | `41`
| ArrayLength                     | `42`
| ArrayClear                      | `43`
| StringToLower                   | `44`
| StringToUpper                   | `45`
| StringEquals                    | `46`
| StringToByteArray               | `47`
| StringLength                    | `48`
| StringSize                      | `49`
| StdoutWrite                     | `50`
| StderrWrite                     | `51`
| StdinRead                       | `52`
| FileOpen                        | `53`
| FileWrite                       | `54`
| FileRead                        | `55`
| FileFlush                       | `56`
| FileSize                        | `57`
| FileSeek                        | `58`
| LoadModule                      | `59`
| SetAttribute                    | `60`
| GetAttribute                    | `61`
| SetPrototype                    | `62`
| GetPrototype                    | `63`
| LocalExists                     | `64`
| ProcessSpawn                    | `65`
| ProcessSendMessage              | `66`
| ProcessReceiveMessage           | `67`
| ProcessCurrent                  | `68`
| SetParentLocal                  | `69`
| GetParentLocal                  | `70`
| ObjectEquals                    | `71`
| GetToplevel                     | `72`
| GetNil                          | `73`
| AttributeExists                 | `74`
| RemoveAttribute                 | `75`
| GetAttributeNames               | `76`
| TimeMonotonic                   | `77`
| GetGlobal                       | `78`
| SetGlobal                       | `79`
| Throw                           | `80`
| SetRegister                     | `81`
| TailCall                        | `82`
| ProcessSuspendCurrent           | `83`
| IntegerGreaterOrEqual           | `84`
| IntegerSmallerOrEqual           | `85`
| FloatGreaterOrEqual             | `86`
| FloatSmallerOrEqual             | `87`
| CopyBlocks                      | `88`
| SetAttributeToObject            | `89`
| FloatIsNan                      | `90`
| FloatIsInfinite                 | `91`
| FloatFloor                      | `92`
| FloatCeil                       | `93`
| FloatRound                      | `94`
| Drop                            | `95`
| ProcessSetBlocking              | `96`
| StdoutFlush                     | `97`
| StderrFlush                     | `98`
| FileRemove                      | `99`
| Panic                           | `100`
| Exit                            | `101`
| Platform                        | `102`
| FileCopy                        | `103`
| FileType                        | `104`
| FileTime                        | `105`
| TimeSystem                      | `106`
| TimeSystemOffset                | `107`
| TimeSystemDst                   | `108`
| DirectoryCreate                 | `109`
| DirectoryRemove                 | `110`
| DirectoryList                   | `111`
| StringConcat                    | `112`
| HasherNew                       | `113`
| HasherWrite                     | `114`
| HasherFinish                    | `115`
| Stacktrace                      | `116`
| ProcessTerminateCurrent         | `117`
| StringSlice                     | `118`
| BlockMetadata                   | `119`
| StringFormatDebug               | `120`
| StringConcatMultiple            | `121`
| ByteArrayFromArray              | `122`
| ByteArraySet                    | `123`
| ByteArrayAt                     | `124`
| ByteArrayRemove                 | `125`
| ByteArrayLength                 | `126`
| ByteArrayClear                  | `127`
| ByteArrayEquals                 | `128`
| ByteArrayToString               | `129`
| EnvGet                          | `130`
| EnvSet                          | `131`
| EnvVariables                    | `132`
| EnvHomeDirectory                | `133`
| EnvTempDirectory                | `134`
| EnvGetWorkingDirectory          | `135`
| EnvSetWorkingDirectory          | `136`
| EnvArguments                    | `137`
| EnvRemove                       | `138`
| BlockGetReceiver                | `139`
| BlockSetReceiver                | `140`
| RunBlockWithReceiver            | `141`
| ProcessSetPanicHandler          | `142`
| ProcessAddDeferToCaller         | `143`
| SetDefaultPanicHandler          | `144`
| ProcessPinThread                | `145`
| ProcessUnpinThread              | `146`
| LibraryOpen                     | `147`
| FunctionAttach                  | `148`
| FunctionCall                    | `149`
| PointerAttach                   | `150`
| PointerRead                     | `151`
| PointerWrite                    | `152`
| PointerFromAddress              | `153`
| PointerAddress                  | `154`
| ForeignTypeSize                 | `155`
| ForeignTypeAlignment            | `156`
| StringToInteger                 | `157`
| StringToFloat                   | `158`
| FloatToBits                     | `159`
| ProcessIdentifier               | `160`
| SocketCreate                    | `161`
| SocketWrite                     | `162`
| SocketRead                      | `163`
| SocketAccept                    | `164`
| SocketReceiveFrom               | `165`
| SocketSendTo                    | `166`
| SocketAddress                   | `167`
| SocketGetOption                 | `168`
| SocketSetOption                 | `169`
| SocketBind                      | `170`
| SocketListen                    | `171`
| SocketConnect                   | `172`
| SocketShutdown                  | `173`

## Catch entries

A catch entry specifies a sequence of instructions that may throw an error, and
what instruction to jump to when this happens. Each entry consists out of the
following fields:

1. A `u16` containing the start position of the instruction range.
1. A `u16` containing the end position of the instruction range.
1. A `u16` containing the instruction position to jump to.
1. A `u16` containing the register to store the error value in.

Instructions are zero-indexed, meaning the first instruction starts at index
`0`.

[tac]: https://en.wikipedia.org/wiki/Three-address_code
