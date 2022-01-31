---
title: "Inko Progress Report: January 2022"
date: 2022-01-31 13:28:19 UTC
---

It's been a while since our last update, with the last release being in December
2020 and the last progress report being published in December 2019. Not because
there was no progress, but because we decided to make various big changes to
Inko.

<!-- READ MORE -->

## Memory management and a new compiler

The first big change is that we're doubling down on removing the use of garbage
collection, instead using a single ownership model to manage memory. This
provides many benefits, and we believe it will make Inko a compelling language
to use when compared to the likes of Ruby, Python, and similar languages. You
can read more about this in the article ["Friendship ended with the garbage
collector"](https://yorickpeterse.com/articles/friendship-ended-with-the-garbage-collector/).

As part of this effort we're rewriting our compiler: instead of using Ruby
we're using Rust. The Ruby compiler has always been more of a prototype rather
than a production compiler, and adjusting it to support the new memory model
proved impossible. Since we're already using Rust for the VM, it made sense to
also use it for the compiler. This change should also make it easier to install
Inko, as Ruby is no longer required.

Based on recent progress, we estimate about 80% of the work is done, and we
intend to finish the remaining 20% in February. Once the type-checker is
implemented we'll start work on lifetime analysis, code generation, and some
basic compile-time optimisations (e.g. inlining trivial getter methods). Other
optimisations such as dead code removal, devirtualisation and more/better
inlining is something we intend to focus on after releasing all the current
changes.

## A new website

As part of all this work we've also given the website an overhaul. We've decided
to release this overhaul ahead of time rather than wait until the next release,
making it easier to explain the direction Inko is heading in, and what it will
have to offer.

The manual has yet to be updated, we'll do so once all changes have been merged
into the `master` branch.

## We're working on Inko full-time

Another big change is that we're now working on Inko full-time, as announced in
[this
article](https://yorickpeterse.com/articles/im-leaving-gitlab-to-work-on-inko-full-time/).
This is already proving to have a positive impact, as in January alone we've
already made a lot of progress. For the time being we are self-funding the
development of Inko. In the future we hope to gather enough monthly donations to
cover the development costs. If you'd like to support this effort, please
consider donating using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).

## Following along

If you'd like to follow along with the progress made, we recommend joining the
[Matrix channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko`
channel in the [/r/ProgrammingLanguages Discord
server](https://discord.gg/yqWzmkV).
