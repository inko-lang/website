---
author: Yorick Peterse
title: "Inko progress report: June 2022"
date: "2022-07-02 11:14:05 UTC"
---

After a three week vacation, followed by a productive week of working on the
compiler, it's time for another progress report.

## Pattern matching

It took a while, but Inko's pattern matching implementation is complete. This
includes type-checking, exhaustiveness checking, and generating Inko's mid-level
IR. This implementation is used for both `match` and `let` expressions.

## Continued work on MIR

In past progress reports I stated much of the work on MIR was complete. While
working on implementing pattern matching I realised this wasn't quite the case.
For example, generating MIR has yet to be enabled for all types of methods, and
the MIR generated for certain operations inside closures wasn't correct. Since
completing pattern matching, I've been focusing on wrapping up the remaining
work. At this stage it's a little difficult to say how much more time is
necessary, but I expect we're still on track for a new Inko release by the end
of this summer.

## Plans for July

For July the plan is to enable generating of MIR for all types of methods
(instance methods, static methods, etc), determine what MIR to generate when
spawning processes, and to clean up the MIR generator in several places.

If you'd like to follow along with the progress made, we
recommend joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). If
you'd like to support Inko financially, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
