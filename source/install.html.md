---
title: Installing Inko
created_at: 2018-07-15
keywords:
  - inko
  - programming language
  - installation
description: How to install Inko on your computer.
---

1. TOC
{:toc}

Inko is currently still in the early stages of development. Unfortunately, this
means that the installation procedure is a bit more complicated than we would
like it to be, depending on your platform.

## Officially supported platforms

Inko supports any Unix-like platform, such as Linux, Mac OS, or BSD.

Inko also supports Windows, but this requires the use of a Unix like
compatibility layer such as [MSYS2](http://www.msys2.org/) or [Linux for
Windows](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Currently
we only provide official support for MSYS2 environments.

## Installing using ienv (recommended)

[ienv](https://gitlab.com/inko-lang/ienv) is the official version manager of
Inko. Using ienv you can easily install, remove, and use different versions of
Inko during development.

### Requirements

Ienv currently only supports Unix platforms, and requires the following
software:

* Bash 4.0 or newer
* Curl
* Grep
* (GNU) coreutils
* (GNU) findutils
* Make 4.0 or newer
* Rust 1.31 or newer, using the 2018 edition
* Ruby 2.3 or newer (for the compiler)
* autoconf
* automake
* texinfo
* clang
* libtool

### Installing ienv

To use ienv, we must first install it. The easiest way to install ienv is to
clone its Git repository:

    git clone https://gitlab.com/inko-lang/ienv.git ~/.local/share/ienv

Now you need to add the `ienv` executable to your PATH for your shell of choice.
For Bash you would add the following to `~/.bashrc`:

    export PATH="${PATH}:$HOME/.local/share/ienv/bin"

For [Fish](https://fishshell.com/), add the following to
`~/.config/fish/config.fish`:

    set -x PATH $PATH $HOME/.local/share/ienv/bin

### Installing Inko using ienv

Once installed, you can install versions of Inko as follows:

    ienv install 0.2.0

This would install version 0.2.0 of Inko.

ienv will not automatically set a version to use for you, instead you need to do
so manually. This can be done by running the following

    ienv default 0.2.0

This will set `0.2.0` as the default version.

Whenever possible, ienv will use precompiled packages. This removes the need for
having to compile the virtual machine, which in turn makes the installation
procedure easier and faster. If no precompiled package is available, ienv will
install Inko from source instead.

You can list installed versions by running the `list` command:

    ienv list

Known versions (= the ones you can install) can be displayed using the `known`
command:

    ienv known

For more information and the available commands, run `ienv --help`, or refer to
[ienv's README](https://gitlab.com/inko-lang/ienv/blob/master/README.md).

## Installing from Git

Installing from source has the same requirements as installing from source using
ienv. Assuming these requirements are met, first we need to clone the Git
repository:

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
located in `~/.local/bin/ivm`, and the runtime and compiler will be in
`~/.local/lib/inko`.

When installing from source, you need to manually tell the `inko` or `inkoc`
executable where the runtime (the core plus standard library) is located. The
easiest way of doing this is by setting `INKOC_HOME` to the directory containing
the runtime. For example, if Inko is installed in `~/.local/share/inko` you
would use this variable as follows:

```inko
INKOC_HOME=~/.local/share/inko/lib/inko inko program_here.inko
```

To persist this variable you can add it to your shell's configuration file such
as `~/.bashrc` for Bash, and `~/.config/fish/config.fish` for Fish.
