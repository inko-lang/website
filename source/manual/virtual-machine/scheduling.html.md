---
title: Scheduling
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Processes are scheduled using a preemptive scheduler. Each process is allowed to
consume a certain number of "reductions", before it is suspended. A reduction
is just the reducing of a counter until it reaches `0`.

## Pools

Processes are executed in one of two thread pools: a primary pool, and a
secondary pool. The primary pool is used for executing regular processes, while
a secondary pool is used for executing processes that may perform blocking
operations, such as reading from a file.

Threads in these pools use [work stealing][work-stealing], though threads from
one pool can not steal processes to run from another pool.

## Suspending processes

A process can be suspended due to a variety of reasons, such as a process
consuming all reductions, or receiving a message when there aren't any.

A separate thread called the "suspension worker" will periodically check if any
suspended processes need to be resumed again, moving them back into the right
process pool when necessary.

[work-stealing]: https://en.wikipedia.org/wiki/Work_stealing
