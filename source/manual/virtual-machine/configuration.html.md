---
title: Configuration
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

IVM can be configured using two different methods:

1. Command-line options.
1. Environment variables.

In general IVM favours the use of environment variables over command-line
options, as environment variables are easier to persist.

## Command-line options

### Bytecode include directory

The `-I` / `--include` option can be specified multiple times, and is used to
add a directory to the list of bytecode directories. When IVM loads a bytecode
file, it will try to find it in one of these directories.

## Environment variables

### INKO_PRIMARY_THREADS

Controls the number of threads used for running regular processes.

Defaults to the number of logical CPU cores.

### INKO_BLOCKING_THREADS

Controls the number of threads used for running processes that perform blocking
operations.

Defaults to the number of logical CPU cores.

### INKO_GC_THREADS

Controls the number of threads used in the fixed-size garbage collection
coordination thread pool.

Defaults to half the number of logical CPU cores.

### INKO_TRACER_THREADS

Controls the number of threads spawned for tracing objects. Each process
collected will have its own pool of tracers, spawned when needed and terminated
when all work is done.

Defaults to half the number of logical CPU cores.

### INKO_REDUCTIONS

An integer specifying the number of reductions that take place before a process
is suspended.

Defaults to `1000`.

### INKO_YOUNG_THRESHOLD

An integer specifying the amount of memory that can be allocated in the young
generation before triggering a young collection.

Defaults to `8 388 608` (8 MB).

### INKO_MATURE_THRESHOLD

An integer specifying the amount of memory that can be allocated in the mature
generation before triggering a full collection.

Defaults to `16 777 216` (16 MB).

### INKO_HEAP_GROWTH_THRESHOLD

A float ranging from `0.0` (0%) to `1.0` (100%), specifying the percentage of
memory that should still remain in use after a garbage collection cycle, before
increasing the process heap's garbage collection threshold.

Defaults to `0.9`.

### INKO_HEAP_GROWTH_FACTOR

A float used to grow the process heap's garbage collection threshold if the
growth threshold is exceeded. The threshold is increased by multiplying it with
this value.

Defaults to `1.5`.

### INKO_PRINT_GC_TIMINGS

When set to `"true"`, the VM will print garbage collection timings to STDERR.
This is an internal option that may be removed at any time.
