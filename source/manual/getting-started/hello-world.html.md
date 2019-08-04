---
title: Hello, world!
---
<!-- vale off -->

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Let's start with the most basic Inko program one can write: "hello world". This
is a program that does one simple thing: print the text "Hello, world!" to
the command line (STDOUT to be exact), then exit.

Let's start by setting up the source file for our program. Create a file called
`hello.inko` and place it anywhere you like. We'll simply refer to this file as
`hello.inko` from now on.

With the file in place, add the following to it, then save it:

```inko
import std::stdio::stdout

stdout.print('Hello, world!')
```

Next, open your command line program of choice, such as Gnome Terminal or iTerm.
Navigate to the directory containing `hello.inko`, then run the following:

```bash
inko hello.inko
```

If all went well, this will print "Hello, world!" to STDOUT. Congratulations,
you just wrote your first Inko program!

## Anatomy

Let's dive into our program and explain how it actually works. After all,
there's no point in writing a program if you don't understand what it does.

We begin the program with the following line:

```inko
import std::stdio::stdout
```

This is known as an "import". Imports are used to load external modules,
allowing you to use them in your own module. In Inko, every file is a module.

Coming from other programming languages, it may be a bit odd that you have to
import a module just to write data to STDOUT. This is necessary because we do
not want to clutter modules with imports that are not used. Since not every
program needs to write to STDOUT, we don't import this module by default.

In this particular case, the module we are importing is `std::stdio::stdout`.
The module is made available using the symbol `stdout`. You can import multiple
symbols, and even rename them, but this will be discussed separately.

Once we have imported our module, we reach the following line:

```inko
stdout.print('Hello, world!')
```

Here `stdout` refers to the module we imported earlier on. `print` is a message
we send to the module, and it takes a `String` as an argument.

## Compiling vs Running

Inko is an interpreted programming language, with a bytecode compiler. What this
means is that source code is first compiled to a set of bytecode files, which
are then executed using a separate program. The `inko` executable takes care of
doing this for us. If we wanted to compile our code manually, we'd have to use
the `inkoc` executable like so:

```
inkoc --release hello.inko
```

This will compile the program, then write the file path to STDOUT. For example,
the output might be the following:

```
/home/yorickpeterse/.cache/inko/0.1.0/bytecode/release/43/38021ddc9a3449ace13288a2fac894d1d3e2aaa.inkoc
```

We can then run the program as follows:

```
ivm -I ~/.cache/inko/0.1.0/bytecode/release/ \
    ~/.cache/inko/0.1.0/bytecode/release/43/38021ddc9a3449ace13288a2fac894d1d3e2aaa.inkoc
```

`ivm` is the executable of the virtual machine. The `-I` argument tells the VM
what directory contains our compiled bytecode files. The first positional
argument (the path after the `-I` option and its value) is the bytecode file to
execute. Keep in mind that the exact paths may differ on your own computer.

Since this approach of running a program is a bit cumbersome, we using the
`inko` executable instead.
