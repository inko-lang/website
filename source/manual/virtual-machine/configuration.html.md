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

An integer specifying the number of threads to use for the primary thread pool.

Defaults to the number of logical CPU cores.

### INKO_SECONDARY_THREADS

An integer specifying the number of threads to use for the secondary thread
pool.

Defaults to the number of logical CPU cores.

### INKO_GC_THREADS

An integer specifying the number of threads to use for the garbage collector.

Defaults to `2`.

### INKO_FINALIZER_THREADS

An integer specifying the number of threads to use for finalising objects.

Defaults to `2`.

### INKO_GENERIC_PARALLEL_THREADS

An integer specifying the number of threads to use for various parallel
operations, such as scanning the stack of a process to garbage collect.

Defaults to the number of physical CPU cores.

### INKO_REDUCTIONS

An integer specifying the number of reductions that take place before a process
is suspended.

Defaults to `1000`.

### INKO_SUSPENSION_CHECK_INTERVAL

An integer specifying the number of milliseconds to wait between checking for
suspended processes.

Defaults to `100` (milliseconds).

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

### INKO_MAILBOX_THRESHOLD

An integer specifying the amount of memory that can be allocated in the mailbox
heap before triggering a mailbox garbage collection.

Defaults to `32 768` (32 KB).

### INKO_MAILBOX_GROWTH_FACTOR

A float used to grow the mailbox heap's garbage collection threshold if the
growth threshold is exceeded. The threshold is increased by multiplying it with
this value.

Defaults to `1.5`.

### INKO_MAILBOX_GROWTH_THRESHOLD

A float ranging from `0.0` (0%) to `1.0` (100%), specifying the percentage of
memory that should still remain in use after a garbage collection cycle, before
increasing the mailbox heap's garbage collection threshold.

Defaults to `0.9`.
