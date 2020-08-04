---
title: Instructions
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

IVM has a large number of instructions. Some of these instructions are rather
low-level, while others are high-level instructions such as `DirectoryList`.

## Instruction layout

Each instruction has a fixed size of 16 bytes, and can store up to six
arguments. Instructions have the following fields:

| Field     | Rust Type  | Size
|:----------|:-----------|:----
| opcode    | `u8`       | 1 byte
| line      | `u16`      | 2 bytes
| arguments | `[u16; 6]` | 12 bytes

Each instruction also has one byte used for padding the size to 16 bytes. This
space is reserved, and may be used in the future if we need two bytes to store
opcodes.

## Variable arguments

Some instructions need a variable number of arguments. In this case, they
require at least two arguments to be specified in the instruction itself:

1. The number of arguments (e.g. the number of values in an array).
1. The register containing the first argument.

These instructions then expect all arguments to be in a contiguous order,
starting at the first register specified. When generating bytecode, the compiler
makes sure that these arguments are always in the correct order.

## Instruction list

The exact list of instructions and their arguments is undocumented.  As the
instruction set is not part of the public API and a moving target, keeping the
documentation up to date is challenging. In the future we may provide more
detailed documentation on the instruction set.
