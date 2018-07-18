---
title: Environment variables
---

Inkoc reads a few environment variables to figure out how it should operate.
These environment variables are discussed below.

## INKOC_HOME

To compile an Inko program various source files are necessary. These, along
with third-party modules, are stored in directories relative to this environment
variable.

The default value is `/usr/lib/inko`.

## INKOC_CACHE

When compiling a program, the bytecode files are stored on disk.
These (and possibly other) files are stored in directories relative to this
environment variable.

The default value is `$XDG_CACHE_HOME/inko`. If `$XDG_CACHE_HOME` is not set,
then the default is `$HOME/.cache/inko`.
