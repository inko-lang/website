---
title: About
created_at: 2018-07-14
keywords:
  - inko
  - programming language
  - about
description: About the Inko Programming language.
---

Inko is an object-oriented programming language, focusing on making it fun and
easy to write concurrent programs. Its creator, [Yorick
Peterse](https://gitlab.com/yorickpeterse), first had the idea of building a
programming language in 2013. It wasn't until early 2015 before the first few
lines of code were written.

From the beginning the idea was to build an object-oriented programming
language, though the idea did not extend much beyond that back in 2013. Over the
years the goals of the language were narrowed down to what it is today. This
took many iterations, with both the syntax and language as a whole changing
frequently over the years.

## Features

Inko brings several features to the table to address issues found in many other
languages. For example, instead of using shared memory, every process uses its
own heap. This removes the need for having to worry about synchronisation access
to shared memory, and removes the need for having to debug problems that arise
from using shared memory. Other noteworthy features include, but are not limited
to:

1. An error handling model that prevents unexpected runtime errors.
1. Using message passing for expressions typically implemented using statements,
   such as `if` and `while`.
1. Preemptive multitasking, ensuring all processes are given an equal share of
   available resources.
1. Using traits for composition, instead of relying on inheritance.
1. Gradual typing, allowing you to choose between the safety of static typing
   and the flexibility of dynamic typing.

By combining these features, we hope to provide a programming language that
allows one to write concurrent object-oriented programs, without the headaches.

## Inspiration

Inko draws inspiration from many other languages, such as: Smalltalk, Self,
Ruby, Erlang, and Rust. Some of Inko's features are borrowed from these
languages. For example, the concurrency model is heavily inspired by Erlang, and
the use of message passing for `if` and the likes is taken from Smalltalk.

## Getting started

Interested in getting started with Inko? First make sure to [install
Inko](/install), then head over to the [documentation](/documentation) to find
out more.
