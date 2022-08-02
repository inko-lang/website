---
author: Yorick Peterse
title: "Inko Progress Report: July 2022"
date: 2022-08-02 13:10:05 UTC
---

In [last month's progress report](/news/inko-progress-report-june-2022/) I
talked about wrapping up the work on MIR. I'm pleased to report that not only is
the work on MIR finished, I was also able to wrap up the compiler phase that
turns MIR into bytecode. This means that for the first time in over a year both
the compiler and VM are in a working state again.

In it's current state, Inko is able to run basic programs without outright
crashing. That may sound a bit odd, but considering _a lot_ has changed, I am
pleasantly surprised that thus far I've only encountered small issues here and
there, opposed to fundamental problems requiring a lot of work to resolve.

That's not to say there are no bugs at all. For example, when pattern matching
against certain values we may decrement reference counts for the value more than
we increment the counts, resulting in integer overflows. I also found (and
resolved) various bugs that would result in segmentation faults. Most of these
bugs were caused by the compiler, such as due to it generating code that used
the wrong method IDs/offsets for method calls.

Another bug was a classic case of "it's technically correct, but still broken":
when pushing a value into an Array using its `push` method, the pushed value
would be dropped before returning from `push`, because the compiler wasn't aware
the intrinsic used for pushing values into an Array takes ownership of the
value. The solution was to introduce a "moved" intrinsic which marks a value as
moved, preventing it from being dropped when it goes out of scope, then using
this intrinsic where needed.

## Performance

Performance wise there's a lot of work to do. Method calls in particular are
more expensive than necessary, as the data structures used to represent call
frames are heap allocated and released for every frame/method call. This means
that 1000 method calls require at least 1000 heap allocations, and 1000
releases. For now this isn't a priority though, as I'm more concerned with
making everything correct rather than making it fast. After all, you can have
the fastest VM on the planet, but if it crashes every two lines it's not useful.

The long term plan is to switch Inko from an interpreted language to a compiler
language. Initially I thought about compiling to C, but the more time I spent
looking into this, the more I realised it may be better to use a library such as
[Cranelift](https://github.com/bytecodealliance/wasmtime/tree/main/cranelift)
and compile straight to machine code. The summary is that this would allow us to
avoid the many footguns of C, and not by restricted by the limitations of C and
its various compilers. This is of course a lot of work, so it's not something
I'll actively pursue at least for a while.

## Plans for August

In August I'll continue work on resolving bugs, rewriting the documentation,
updating all unit tests for the standard library, and any other work necessary
for the upcoming release. My aim is to release a new version by the end of
September.

If you'd like to follow along with the progress made, consider joining the
[Matrix channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko`
channel in the [/r/ProgrammingLanguages Discord
server](https://discord.gg/yqWzmkV). If you'd like to support Inko financially,
you can do so using [GitHub Sponsors](https://github.com/sponsors/YorickPeterse).
