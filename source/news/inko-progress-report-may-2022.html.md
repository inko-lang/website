---
author: Yorick Peterse
title: "Inko Progress Report: May 2022"
date: 2022-06-02 16:29:45 UTC
---

In May most of the work on Inko's mid-level IR ("MIR") was completed, including
lowering of closures. What remains is implementing the `match` expression.

## Pattern matching

Pattern matching proved to be more challenging than anticipated. Originally I
had hoped to complete the work in May, but just investigating and understanding
the various pattern matching and exhaustiveness checking algorithms took
almost three weeks. As part of this effort I implemented two algorithms in [this
project](https://gitlab.com/yorickpeterse/pattern-matching-in-rust). The
algorithms I looked into (and implemented) are:

1. [ML pattern compilation and partial evaluation](https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.48.1363)
2. [How to compile pattern matching](https://julesjacobs.com/notes/patternmatching/patternmatching.pdf)

After evaluating both, I opted to go with the second algorithm due to its
simplicity, and started to include it in Inko's compiler.

## Potentially compiling Inko to C

Aside from this I started [toying with the idea of one day compiling Inko to
C](https://gitlab.com/inko-lang/inko/-/issues/248), with its runtime written in
Rust.

The reason for looking into this is as follows: interpreters without JITs won't
be fast enough for large projects. Writing JITs in turn is incredibly
challenging and time consuming. It also increases the maintenance burden: we
have to maintain a VM, a compiler, a standard library _and_ a JIT. In contrast,
if Inko is compiled to native code directly we wouldn't need a JIT or VM.

Traditionally one would use LLVM for writing a compiler, but I'm personally not
a fan of it. LLVM doesn't follow semantic versioning, different OS' and Linux
distributions all ship different versions of LLVM, and its APIs have a tendency
to change often. The result is that many using LLVM end up vendoring it. This
can complicate packaging of a compiler, as some Linux distributions may refuse
the use of a bundled LLVM while whatever version they ship isn't compatible with
your compiler. LLVM is also rather slow, leading to a frustrating developer
experience.

Compiling to C is an interesting alternative: C compilers are ubiquitous,
generally quite fast, and pretty much any platform is supported. You also get
debugger (e.g. GDB) and profiling support out of the box, something you have to
implement yourself when writing an interpreter (possibly twice if you have a JIT
compiler).

Porting Inko's runtime to C is something I want to avoid, for two reasons:

1. It would take a lot of time.
2. I'm not comfortable writing large amounts of C code, due to the amount of
   footguns it includes.

This lead me to the idea discussed in the issue: we could write the runtime in
Rust, expose it as a static library, convert Inko source code to C, then
statically link against that library. The runtime library would be compiled
once, ensuring projects using Inko aren't affected by Rust's slow compile times.
Using link time optimisation (LTO) code from the static library can be inlined
as if it were compiled directly with the program.

At least that's the theory: I have yet to confirm this works as well in practise
as I hope it does.

For now this isn't a priority, instead it's something I'll look into every now
and then.

## Plans for June

In June I'll be on vacation for three weeks, after not having had a proper
vacation in several years. As such there probably will be fewer changes made
this month, though I plan on at least finishing the remaining bits and pieces of
MIR (including pattern matching). Depending on how things go, I may also start
looking into turning MIR into Inko bytecode.

If you'd like to follow along with the progress made, we
recommend joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). If
you'd like to support Inko financially, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
