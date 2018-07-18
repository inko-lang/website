---
title: Directories
---

Inkoc needs a variety of files located in different places, such as the Inko
runtime and any third-party modules. The following directories are currently
used:

* `$INKOC_HOME/$VERSION/runtime`: this directory stores the source code of the
  core and standard libraries.
* `$INKOC_HOME/$VERSION/packages`: a directory containing third-party packages.
* `$INKOC_CACHE/$VERSION/bytecode/`: the directory to store compiled bytecode
  files in. This directory will contain a sub-directory for every build mode:
    * `debug`: bytecode files compiled using the "debug" mode.
    * `release`: bytecode files compiled using the "release" mode.
    * `test`: bytecode files compiled using the "test" mode.

Here the following variables are used:

* `$INKOC_HOME`: the value of the `INKOC_HOME` environment variable.
* `$INKOC_CACHE`: the value of the `INKOC_CACHE` environment variable.
* `$VERSION`: the current version of Inko.
