---
title: Installing Inko
created_at: 2018-07-15
keywords:
  - inko
  - programming language
  - installation
description: How to install Inko on your computer.
---

Inko is currently still in the early stages of development. Unfortunately, this
means that the installation procedure is a bit more complicated than we would
like it to be. Currently the only available installation is installing from
source, but we aim to provide more (and easier) methods in the future.

## Source Installation

To install from source you will need:

1. Git
1. Ruby 2.4 or newer with RubyGems, as the compiler is currently written in
   Ruby.
1. Rust 1.28 nightly or newer. Stable Rust is unfortunately not supported at the
   moment.
1. Make 4.0 or newer

Assuming these requirements are met, first we need to clone the Git repository:

```bash
git clone https://gitlab.com/inko-lang/inko.git
```

We can then install everything by running the following:

```bash
sudo make install
```

This will try to install Inko in a variety of directories relative to `/usr`. If
you don't like this, you can change the prefix as follows:

```bash
make install PREFIX=~/.local
```

This will then install Inko in `~/.local`. The IVM executable will then be
located in `~/.local/bin/ivm`, and the runtime will be in `~/.local/lib/inko`.

The compiler is always installed using the `gem` command, regardless of what
value `PREFIX` is set to.
