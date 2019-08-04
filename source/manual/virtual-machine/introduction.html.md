---
title: Introduction
---
<!-- vale off -->

Inko's virtual machine ("IVM" for short) is a register based, bytecode virtual
machine, written in [Rust](https://www.rust-lang.org/). IVM uses preemptive
multitasking for executing processes, and manages memory using a garbage
collector and allocator based on [Immix][immix].

The bytecode executed by the VM is reasonably compact, although it could
probably be optimised a bit more.

IVM uses [prototype-based objects][prototypes] internally, although this is
mostly hidden from the language.

IVM can be compiled using [musl](https://www.musl-libc.org/), allowing you to
easily distribute the executable across different versions of the same operating
system.

The executable is reasonably small: around 4.2 MB when using musl without
stripping debugging symbols, and roughly 1.1 MB after stripping debugging
symbols.

Currently there is no JIT, though we hope to implement one some time in the
future.

[immix]: http://www.cs.utexas.edu/users/speedway/DaCapo/papers/immix-pldi-2008.pdf
[prototypes]: https://en.wikipedia.org/wiki/Prototype-based_programming
