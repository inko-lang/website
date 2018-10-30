---
title: Instructions
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

IVM has quite a few instructions, 139 at the time of writing to be exact. Some
of these instructions are rather low-level, while others are high-level
instructions such as `DirectoryList`.

The instruction set is a register based instruction set, based on
[Three-address code][tac].

## Available instructions

### ArrayAt

Gets the value of an array index.

This instruction requires three arguments:

1. The register to store the value in.
2. The register containing the array.
3. The register containing the index.

This instruction will set nil in the target register if the array index is out
of bounds. A negative index can be used to indicate a position from the end of
the array.

### ArrayClear

Removes all elements from an array.

This instruction requires one argument: the register of the array.

### ArrayLength

Gets the amount of elements in an array.

This instruction requires two arguments:

1. The register to store the length in.
2. The register containing the array.

### ArrayRemove

Removes a value from an array.

This instruction requires three arguments:

1. The register to store the removed value in.
2. The register containing the array to remove a value from.
3. The register containing the index.

This instruction sets nil in the target register if the index is out of bounds.
A negative index can be used to indicate a position from the end of the array.

### ArraySet

Inserts a value in an array.

This instruction requires four arguments:

1. The register to store the result (the inserted value) in.
2. The register containing the array to insert into.
3. The register containing the index (as an integer) to insert at.
4. The register containing the value to insert.

If an index is out of bounds the array is filled with nil values. A negative
index can be used to indicate a position from the end of the array.

### AttributeExists

Checks if an attribute exists in an object.

This instruction requires three arguments:

1. The register to store the result in (true or false).
2. The register containing the object to check.
3. The register containing the attribute name.

### BlockMetadata

Obtains metadata from a block.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the block to obtain the data from.
3. The register containing an integer describing what kind of information to
   obtain.

The following kinds of metadata are available:

| Value | Meaning
|:------|:----------------------------------
| `0`   | The name of the block.
| `1`   | The file path of the block.
| `2`   | The line number of the block.
| `3`   | The argument names of the block.
| `4`   | The number of required arguments.
| `5`   | A boolean indicating if the last argument is a rest argument.

### ByteArrayAt

Returns the value at the given position in a byte array.

This instruction requires three arguments:

1. The register to store the value in.
2. The register containing the byte array to retrieve the value from.
3. The register containing the value index.

This instruction will set the target register to nil if no value was found.

### ByteArrayClear

Removes all elements from a byte array.

This instruction only requires one argument: the register containing the byte
array to clear.

### ByteArrayEquals

Checks two byte arrays for equality.

This instruction requires three arguments:

1. The register to store the result in as a boolean.
2. The register containing the byte array to compare.
3. The register containing the byte array to compare with.

### ByteArrayFromArray

Creates a new byte array from an array of integers.

This instruction requires two arguments:

1. The register to store the result in.
2. The register containing an array of integers to use for creating the byte
array.

This instruction will panic if any of the bytes is not in the range 0..256.

### ByteArrayLength

Gets the amount of elements in a byte array.

This instruction requires two arguments:

1. The register to store the length in.
2. The register containing the byte array.

### ByteArrayRemove

Removes a value from a byte array.

This instruction requires three arguments:

1. The register to store the removed value in.
2. The register containing the byte array to remove a value from.
3. The register containing the index of the value to remove.

This instruction will set the target register to nil if no value was removed.

### ByteArraySet

Inserts a value into a byte array.

This instruction requires four arguments:

1. The register to store the written value in, as an integer.
2. The register containing the byte array to write to.
3. The register containing the index to store the byte at.
4. The register containing the integer to store in the byte array.

This instruction will panic if any of the bytes is not in the range 0..256.

Unlike ArraySet, this instruction will panic if the index is out of bounds.

### ByteArrayToString

Converts a byte array to a string.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the byte array to convert.
3. The register containing a boolean indicating if the input array should be
drained.

### CopyBlocks

Copies all of the blocks of one object into another object.  Only blocks defined
directly on the source object will be copied.

This instruction requires two arguments:

1. The register containing the object to copy the blocks to.
2. The register containing the object to copy the blocks from.

### DirectoryCreate

Creates a new directory.

This instruction requires three arguments:

1. The register to store the result in, which is always `nil`.
2. The register containing the path to create.
3. A register containing a boolean. When set to `true` the path is created
recursively.

This instruction may throw an IO error as a string.

### DirectoryList

Lists the contents of a directory.

This instruction requirs two arguments:

1. The register to store the result in, as an array of strings.
2. The register containing the path to the directory.

This instruction may throw an IO error as a string.

### DirectoryRemove

Removes an existing directory.

This instruction requires three arguments:

1. The register to store the result in, which is always `nil`.
2. The register containing the path to remove.
3. A register containing a boolean. When set to `true` the contents of the
   directory are removed before removing the directory itself.

This instruction may throw an IO error as a string.

### Drop

Immediately drops the value of an object, if any.

This instruction takes one argument: the register containing the object for
which to drop the value.

If the object has no value this instruction won't do anything.

Once dropped the value of the object should no longer be used as its memory may
have been deallocated.

### Exit

Terminates the VM with a given exit status.

This instruction takes one argument: a register containing an integer to use for
the exit status.

### FileCopy

Copies a file from one location to another.

This instruction requires three arguments:

1. The register to store the number of copied bytes in as an integer.
2. The register containing the file path to copy.
3. The register containing the new path of the file.

### FileFlush

Flushes a file.

This instruction requires one argument: the register containing the file to
flush.

This instruction may throw an IO error as a string.

### FileOpen

Opens a file handle in a particular mode (read-only, write-only, etc).

This instruction requires X arguments:

1. The register to store the file object in.
2. The path to the file to open.
3. The register containing an integer that specifies the file open mode.

The available file modes supported are as follows:

| Value | Mode
|:------|:---------
| `0`   | read-only
| `1`   | write-only
| `2`   | append-only
| `3`   | read+write
| `4`   | read+append

This instruction may throw an IO error as a string.

### FileRead

Reads data from a file into an array of bytes.

This instruction requires three arguments:

1. The register to store the number of read bytes in.
2. The register containing the file to read from.
3. The register containing the byte array to read the data into.
4. The register containing the number of bytes to read. If set to nil, all
remaining data is read.

This instruction may throw an IO error as a string.

### FileRemove

Removes a file.

This instruction takes two arguments:

1. The register to store the result in. This register will be set to nil upon
success.
2. The register containing the path to the file to remove.

This instruction may throw an IO error as a string.

### FileSeek

Sets a file cursor to the given offset in bytes.

This instruction requires three arguments:

1. The register to store the new cursor position in.
2. The register containing the input file.
3. The offset to seek to as an integer. This integer must be greater than 0.

This instruction may throw an IO error as a string.

### FileSize

Returns the size of a file in bytes.

This instruction requires two arguments:

1. The register to store the size of the file in.
2. The register containing the path to the file.

This instruction may throw an IO error as a string.

### FileTime

Gets the creation, modification or access time of a file.

This instruction requires three arguments:

1. The register to store the result in as a float.
2. The register containing the file path of the file.
3. The register containing an integer indicating what kind of timestamp to
   retrieve.

This instruction will throw an error message (as a String) if the file's
metadata could not be retrieved.

This instruction will panic if the timestamp kind is invalid. The following
timestamp kinds are available:

| Value | Meaning
|:------|:-------------------------
| `0`   | The creation time.
| `1`   | The modification time.
| `2`   | The access time.

### FileType

Gets the file type of a path.

This instruction requires two arguments:

1. The register to store the result in as an integer.
2. The register containing the path to check.

This instruction can produce the following values:

1. `0`: the path does not exist.
2. `1`: the path is a file.
3. `2`: the path is a directory.

### FileWrite

Writes a string to a file.

This instruction requires three arguments:

1. The register to store the amount of written bytes in.
2. The register containing the file object to write to.
3. The register containing the string or byte array to write.

This instruction may throw an IO error as a string.

### FloatAdd

Adds two floats

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the receiver.
3. The register of the float to add.

### FloatCeil

Gets the ceiling of a float.

This instruction takes two arguments:

1. The register to store the result in as a float.
2. The register containing the float.

### FloatDiv

Divides two floats

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the receiver.
3. The register of the float to divide with.

### FloatEquals

Checks if two floats are equal.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the float to compare.
3. The register containing the float to compare with.

The result of this instruction is either boolean true or false.

### FloatFloor

Gets the floor of a float.

This instruction takes two arguments:

1. The register to store the result in as a float.
2. The register containing the float.

### FloatGreater

Checks if one float is greater than the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the float to compare.
3. The register containing the float to compare with.

The result of this instruction is either boolean true or false.

### FloatGreaterOrEqual

Checks if one float is greater than or requal to the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the float to compare.
3. The register containing the float to compare with.

The result of this instruction is either boolean true or false.

### FloatIsInfinite

Sets a register to true if a given float register is an infinite number.

This instruction takes two arguments:

1. The register to store the result in.
2. The register containing the float to check.

### FloatIsNan

Sets a register to true if a given float register is a NaN value.

This instruction takes two arguments:

1. The register to store the result in.
2. The register containing the float to check.

### FloatMod

Gets the modulo of a float

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the receiver.
3. The register of the float argument.

### FloatMul

Multiplies two floats

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the receiver.
3. The register of the float to multiply with.

### FloatRound

Rounds a float to the nearest number.

This instruction takes three arguments:

1. The register to store the result in as a float.
2. The register containing the float.
3. The register containing an integer indicating the number of decimals to round
to.

### FloatSmaller

Checks if one float is smaller than the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the float to compare.
3. The register containing the float to compare with.

The result of this instruction is either boolean true or false.

### FloatSmallerOrEqual

Checks if one float is smaller than or requal to the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the float to compare.
3. The register containing the float to compare with.

The result of this instruction is either boolean true or false.

### FloatSub

Subtracts two floats

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the receiver.
3. The register of the float to subtract.

### FloatToInteger

Converts a float to an integer

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the float to convert.

### FloatToString

Converts a float to a string

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the float to convert.

### GetArrayPrototype

Stores the array prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetAttribute

Gets an attribute from an object and stores it in a register.

This instruction requires three arguments:

1. The register to store the attribute's value in.
2. The register containing the object from which to retrieve the attribute.
3. The register containing the attribute name.

If the attribute does not exist the target register is set to nil.

### GetAttributeNames

Gets all the attributes names available on an object.

This instruction requires two arguments:

1. The register to store the attribute names in.
2. The register containing the object for which to get all attributes names.

### GetBlockPrototype

Stores the block prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetBooleanPrototype

Sets the prototype of booleans in a register.

This instruction only requires one argument: the register to store the prototype
in.

### GetFalse

Sets a "false" value in a register.

This instruction requires only one argument: the register to store the object
in.

### GetFloatPrototype

Stores the float prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetGlobal

Gets a global variable and stores it in a register.

This instruction requires two arguments:

1. The register to store the global's value in.
2. The global variable index to get the value from.

### GetIntegerPrototype

Stores the integer prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetLocal

Gets a local variable and stores it in a register.

This instruction requires two arguments:

1. The register to store the local's value in.
2. The local variable index to get the value from.

### GetNil

Sets the nil singleton in a register.

This instruction requires only one argument: the register to store the object
in.

### GetObjectPrototype

Stores the object prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetParentLocal

Gets a local variable in one of the parent bindings.

This instruction requires three arguments:

1. The register to store the local variable in.
2. The number of parent bindings to traverse in order to find the binding to get
the variable from.
3. The local variable index to get.

### GetPrototype

Gets the prototype of an object.

This instruction requires two arguments:

1. The register to store the prototype in.
2. The register containing the object to get the prototype from.

If no prototype was found, nil is set in the register instead.

### GetStringPrototype

Stores the string prototype in a register.

This instruction requires one argument: the register to store the prototype in.

### GetToplevel

Sets the top-level object in a register.

This instruction requires one argument: the register to store the object in.

### GetTrue

Sets a "true" value in a register.

This instruction requires only one argument: the register to store the object
in.

### Goto

Jumps to a specific instruction.

This instruction takes one argument: the instruction index to jump to.

### GotoIfFalse

Jumps to an instruction if a register is not set or set to false.

This instruction takes two arguments:

1. The instruction index to jump to if a register is not set.
2. The register to check.

### GotoIfTrue

Jumps to an instruction if a register is set.

This instruction takes two arguments:

1. The instruction index to jump to if a register is set.
2. The register to check.

### HasherFinish

Returns the hash for the values written to a hasher.

This instruction requires two arguments:

1. The register to store the result in as an integer.
2. The register containing the hasher to fetch the result from.

### HasherNew

Creates a new hasher.

This instruction requires only one argument: the register to store the object
in.

### HasherWrite

Hashes an object

This instruction requires three arguments:

1. The register to store the result in, this is always `nil`.
2. The register containing the hasher to use.
3. The register containing the object to hash.

The following objects can be hashed:

1. Integers
2. Big integers
3. Floats
4. strings
5. Permanent objects

### IntegerAdd

Adds two integers

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the left-hand side object.
3. The register of the right-hand side object.

### IntegerBitwiseAnd

Performs an integer bitwise AND.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the integer to operate on.
3. The register of the integer to use as the operand.

### IntegerBitwiseOr

Performs an integer bitwise OR.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the integer to operate on.
3. The register of the integer to use as the operand.

### IntegerBitwiseXor

Performs an integer bitwise XOR.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the integer to operate on.
3. The register of the integer to use as the operand.

### IntegerDiv

Divides an integer

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the left-hand side object.
3. The register of the right-hand side object.

### IntegerEquals

Checks if two integers are equal.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the integer to compare.
3. The register containing the integer to compare with.

The result of this instruction is either boolean true or false.

### IntegerGreater

Checks if one integer is greater than the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the integer to compare.
3. The register containing the integer to compare with.

The result of this instruction is either boolean true or false.

### IntegerGreaterOrEqual

Checks if one integer is greater than or requal to the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the integer to compare.
3. The register containing the integer to compare with.

The result of this instruction is either boolean true or false.

### IntegerMod

Gets the modulo of an integer

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the left-hand side object.
3. The register of the right-hand side object.

### IntegerMul

Multiplies an integer

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the left-hand side object.
3. The register of the right-hand side object.

### IntegerShiftLeft

Shifts an integer to the left.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the integer to operate on.
3. The register of the integer to use as the operand.

### IntegerShiftRight

Shifts an integer to the right.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the integer to operate on.
3. The register of the integer to use as the operand.

### IntegerSmaller

Checks if one integer is smaller than the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the integer to compare.
3. The register containing the integer to compare with.

The result of this instruction is either boolean true or false.

### IntegerSmallerOrEqual

Checks if one integer is smaller than or requal to the other.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the integer to compare.
3. The register containing the integer to compare with.

The result of this instruction is either boolean true or false.

### IntegerSub

Subtracts an integer

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the left-hand side object.
3. The register of the right-hand side object.

### IntegerToFloat

Converts an integer to a float

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the integer to convert.

### IntegerToString

Converts an integer to a string

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the integer to convert.

### LoadModule

Loads a bytecode module and executes it.

A module is only executed the first time it is loaded, after that this
instruction acts like a no-op.

This instruction requires two arguments:

1. The register to store the result in. The first time a module is loaded this
will be set to whatever the module returned, after that it will be set to nil.
2. A register containing the file path to the module, as a string.

### LocalExists

Checks if a local variable exists.

This instruction requires two arguments:

1. The register to store the result in (true or false).
2. The local variable index to check.

### MoveToPool

Moves the current process to the given pool.

This instruction takes one argument: the register containing the pool ID to move
to.

If the process is already running in the given pool this instruction does
nothing.

### ObjectEquals

Checks if two objects are equal.

Comparing equality is done by simply comparing the addresses of both pointers:
if they're equal then the objects are also considered to be equal.

This instruction takes three arguments:

1. The register to store the result in.
2. The register containing the object to compare.
3. The register containing the object to compare with.

The result of this instruction is either boolean true, or false.

### ObjectIsKindOf

Checks if one object is a kind of another object.

An object is considered a kind of another object when the object compared with
is in the prototype chain of the object we're comparing.

This instruction requires three arguments:

1. The register to store the result in as a boolean.
2. The register containing the object to compare.
3. The register containing the object to compare with.

### Panic

Produces a VM panic.

A VM panic will result in a stack trace and error message being displayed, after
which the VM will terminate.

This instruction requires one argument: the register containing the error
message to display.

### Platform

Returns the type of the platform as an integer.

This instruction requires one argument: a register to store the resulting
platform ID in.

### ProcessCurrentPid

Gets the PID of the currently running process.

This instruction requires one argument: the register to store the PID in (as an
integer).

### ProcessReceiveMessage

Receives a message for the current process.

This instruction takes two arguments:

1. The register to store the received message in.
2. A timeout after which the process will resume, even if no message is
received. If the register is set to nil or the value is negative the timeout is
ignored.

If no messages are available the current process will be suspended, and the
instruction will be retried the next time the process is executed.

If a timeout is given that expires the given register will be set to nil.

### ProcessSendMessage

Sends a message to a process.

This instruction takes three arguments:

1. The register to store the message in.
2. The register containing the PID to send the message to.
3. The register containing the message (an object) to send to the process.

### ProcessSpawn

Spawns a new process.

This instruction takes three arguments:

1. The register to store the PID in.
2. The register containing the Block to run in the process.
3. The register containing the ID of the process pool to schedule the process
on. Defaults to the ID of the primary pool.

### ProcessStatus

Gets the status of the given process as an integer.

This instruction takes two arguments:

1. The register to store the status in.
2. The register containing the PID of the process to check.

### ProcessSuspendCurrent

Suspends the current process.

This instruction takes one argument: a register containing the minimum amount of
time (as an integer) the process should be suspended. If the register is set to
nil or contains a negative value the timeout is ignored.

### ProcessTerminateCurrent

Terminates the current process.

This instruction does not take any arguments.

### PrototypeChainAttributeContains

Checks if an object's attribute contains the given value.  This instruction will
walk the prototype chain until a match is found or we run out of objects.

This instruction requires 4 attributes:

1. The register to set the result to as a boolean.
2. The object whos prototype chain to check.
3. The name of the attribute to check.
4. The value to check in the attribute.

### RemoveAttribute

Removes a attribute from an object.

This instruction requires three arguments:

1. The register to store the removed attribute in.
2. The register containing the object from which to remove the attribute.
3. The register containing the attribute name.

If the attribute did not exist the target register is set to nil instead.

### Return

Returns the value in the given register.

This instruction takes two arguments:

1. An integer that indicates if we're performing a regular return (0) or a block
return (1).
2. The register containing the value to return. If no value is given nil will be
returned instead.

When performing a block return we'll first unwind the call stack to the scope
that defined the current block.

### RunBlock

Executes a Block object.

This instruction takes the following arguments:

1. The register to store the return value in.
2. The register containing the Block object to run.
3. An integer indicating the number of positional arguments.
4. An integer indicating the number of keyword arguments.
5. A variable list of positional arguments.
6. A variable list of keyword argument and value pairs. The keyword argument
   names must be interned strings.

### SetArray

Sets an array in a register.

This instruction requires at least one argument: the register to store the
resulting array in. Any extra instruction arguments should point to registers
containing objects to store in the array.

### SetAttribute

Sets an attribute of an object.

This instruction requires three arguments:

1. The register to store the written value in
2. The register containing the object for which to set the attribute.
3. The register containing the attribute name.
4. The register containing the object to set as the value.

### SetAttributeToObject

Sets the attribute of an object to an empty object, but only if the attribute is
not already set.

This instruction requires three arguments:

1. The register to store the object set in.
2. The register containing the object to store the attribute in.
3. The register containing the name of the attribute.

### SetBlock

Sets a Block in a register.

This instruction requires two arguments:

1. The register to store the object in.
2. The index of the CompiledCode object literal to use for creating the Block.

If the underlying CompiledCode object captures any outer locals the block's
binding will have its parent set to the binding of the current context.

A block that captures local variables can not be safely stored in a global
object as this can result in the captured locals outliving the process they were
allocated in.

### SetGlobal

Sets a global variable to a given register's value.

This instruction requires three arguments:

1. The register to store the written value in.
2. The global variable index to set.
3. The register containing the object to store in the variable.

If the object being stored is not a permanent object it will be copied to the
permanent generation.

### SetLiteral

Sets a literal value in a register.

This instruction requires two arguments:

1. The register to store the literal value in.
2. The index to the value in the literals table of the current compiled code
object.

### SetLocal

Sets a local variable to a given register's value.

This instruction requires two arguments:

1. The local variable index to set.
2. The register containing the object to store in the variable.

### SetObject

Sets an object in a register.

This instruction takes three arguments:

1. The register to store the object in.
2. A register containing a truthy/falsy object. When the register contains a
truthy object the new object will be a permanent object.
3. An optional register containing the prototype for the object.

### SetParentLocal

Sets a local variable in one of the parent bindings.

This instruction requires three arguments:

1. The local variable index to set.
2. The number of parent bindings to traverse in order to find the binding to set
the variable in.
3. The register containing the value to set.

### SetPrototype

Sets the prototype of an object.

This instruction requires three arguments:

1. The register to store the new prototype in.
1. The register containing the object for which to set the prototype.
2. The register containing the object to use as the prototype.

### SetRegister

Sets a register to the value of another register.

This instruction requires two arguments:

1. The register to set.
2. The register to get the value from.

### Stacktrace

Produces a stack trace.

This instruction requires the three arguments:

1. The register to store the trace in.
2. A register containing the maximum number of frames to include. If set to nil
all frames will be included.
3. A register containing the number of call frames to skip (from the start of
the stack).

The trace is stored as an array of arrays. Each sub array contains:

1. The path of the file being executed.
2. The name of the ExecutionContext.
3. The line of the ExecutionContext.

The frames are returned in reverse order. This means that the most recent call
frame is the last value in the array.

### StderrFlush

Flushes all output to STDERR.

This instruction takes one argument: a register to set to nil if the output was
flushed successfully.

This instruction may throw an IO error as a string.

### StderrWrite

Writes a string to STDERR and returns the amount of written bytes.

This instruction requires two arguments:

1. The register to store the amount of written bytes in.
2. The register containing the string or byte array to write.

This instruction may throw an IO error as a string.

### StdinRead

Reads all the data from STDIN.

This instruction requires two arguments:

1. The register to store the number of read bytes in.
2. The register containing the byte array to read the data into.
3. The register containing the number of bytes to read. If set to nil, all
remaining data is read.

This instruction may throw an IO error as a string.

### StdoutFlush

Flushes all output to STDOUT.

This instruction takes one argument: a register to set to nil if the output was
flushed successfully.

This instruction may throw an IO error as a string.

### StdoutWrite

Writes a string to STDOUT and returns the amount of written bytes.

This instruction requires two arguments:

1. The register to store the amount of written bytes in.
2. The register containing the string or byte array to write.

This instruction may throw an IO error as a string.

### StringConcat

Concatenates two strings together, producing a new one.

This instruction requires three arguments:

1. The register to store the result in.
2. The register containing the first string.
3. The register containing the second string.

### StringConcatMultiple

Takes an array of string objects and concatenates them together efficiently.

This instruction requires two arguments:

1. The register to store the resulting string in.
2. The register containing the array of strings.

### StringEquals

Checks if two strings are equal.

This instruction requires three arguments:

1. The register to store the result in.
2. The register of the string to compare.
3. The register of the string to compare with.

### StringFormatDebug

Formats a string for debugging purposes.

This instruction requires two arguments:

1. The register to store the result in, as a string.
2. The register containing the string to format.

### StringLength

Returns the amount of characters in a string.

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the string.

### StringSize

Returns the amount of bytes in a string.

This instruction requires two arguments:

1. The register to store the result in.
2. The register of the string.

### StringSlice

Slices a string into a new string.

Slicing operates on the _characters_ of a string, not the bytes.

This instruction requires four arguments:

1. The register to store the new string in.
2. The register containing the string to slice.
3. The register containing the start position.
4. The register containing the number of values to include.

### StringToByteArray

Returns a byte array containing the bytes of a given string.

This instruction requires two arguments:

1. The register to store the result in.
2. The register containing the string to get the bytes from.

### StringToLower

Returns the lowercase equivalent of a string.

This instruction requires two arguments:

1. The register to store the new string in.
2. The register containing the input string.

### StringToUpper

Returns the uppercase equivalent of a string.

This instruction requires two arguments:

1. The register to store the new string in.
2. The register containing the input string.

### TailCall

Performs a tail call on the current block.

This instruction takes the same arguments as RunBlock, except for the register
and block arguments.

### Throw

Throws a value

This instruction requires one arguments: the register containing the value to
throw.

This method will unwind the call stack until either the value is caught, or
until we reach the top level (at which point we terminate the VM).

### TimeMonotonic

Gets the current value of a monotonic clock in seconds.

This instruction requires one argument: the register to set the time in, as a
float.

### TimeSystem

Gets the current system time.

This instruction takes one argument: the register to store the number of seconds
since the Unix epoch in seconds (including fractional seconds), as a Float.

### TimeSystemDst

Determines if DST is active or not.

This instruction requires one argument: the register to store the result in as a
boolean.

### TimeSystemOffset

Gets the system time's offset to UTC in seconds.

This instruction takes one argument: the register to store the offset in as an
integer.

### EnvGet

Reads the value of an environment variable.

This instruction requires two arguments:

1. The register to store the value in, as a string or nil.
2. The register containing the name of the environment variable, as a string.

The result will be nil if the environment variable is not set.

### EnvSet

Sets the value of an environment variable.

This instruction requires three arguments:

1. The register to store the new value in, as a string.
1. The register containing the name of the environment variable, as a string.
1. The register containing the new value, as a string.

### EnvRemove

Removes an environment variable.

This instruction requires two arguments:

1. The register to store the result in, which is currently always nil.
1. The register containing the name of the environment variable to remove, as a
   string.

### EnvHomeDirectory

Gets the home directory of the current user.

This instruction only requires a single argument: the register to store the home
directory in, as a string.

It's possible the home directory is not set, in which case the result of this
instruction will be nil.

### EnvTempDirectory

Gets the temporary directory of the system.

This instruction only requires a single argument: the register to store the
temporary directory in, as a string.

### EnvGetWorkingDirectory

Gets the current working directory.

This instruction only requires a single argument: the register to store the
working directory in, as a string.

This instruction may throw an IO error message as a string.

### EnvSetWorkingDirectory

Changes the current working directory.

This instruction requires two arguments:

1. The register to store the new working directory in.
1. The register containing the new working directory.

This instruction may throw an IO error message as a string.

### EnvArguments

Gets the command-line arguments passed to the running program.

This instruction only requires a single argument: the register to store the
command-line arguments in, as an array of strings.

### BlockGetReceiver

Gets the receiver of a block.

This instruction only requires one argument: the register to store the receiver
in.

### BlockSetReceiver

Sets the receiver of a block.

This instruction requires two arguments:

1. The register to store the new receiver in.
1. The register containing the new receiver.

Most blocks have a receiver by default. One exception are blocks executed when
loading a module. In this case BlockSetReceiver can be used to manually set a
receiver.

### RunBlockWithReceiver

Executes a block with a specific receiver.

This instruction requires at least three arguments:

1. The register to store the return value in.
1. The register containing the block to run.
1. The register containing the receiver.
3. An integer indicating the number of positional arguments.
4. An integer indicating the number of keyword arguments.
5. A variable list of positional arguments.
6. A variable list of keyword argument and value pairs. The keyword argument
   names must be interned strings.

See the RunBlock instruction for more information.

### ProcessSetPanicHandler

Sets a panic handler for the current process.

This instruction requires two arguments:

1. The register to store the new panic handler in.
1. The register containing the new panic handler.

### ProcessAddDeferToCaller

Defers the execution of a block in the scope of the caller.

This instruction requires two arguments:

1. The register to store the deferred block in.
1. The register containing the deferred block to schedule.

### SetDefaultPanicHandler

Sets a new default panic handler.

This instruction requires two arguments:

1. The register to store the new panic handler in.
1. The register containing the new panic handler.

[tac]: https://en.wikipedia.org/wiki/Three-address_code
