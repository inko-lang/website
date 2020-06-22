---
title: Installing Inko
created_at: 2018-07-15
keywords:
  - inko
  - programming language
  - installation
description: How to install Inko on your computer.
---
<!-- vale off -->

1. TOC
{:toc}

## Officially supported platforms

Inko supports any Unix-like platform, such as Linux, Mac OS, or BSD.

Inko also supports Windows, but this requires the use of a Unix like
compatibility layer such as [MSYS2](http://www.msys2.org/) or [Linux for
Windows](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Currently
we only provide official support for MSYS2 environments.

Inko requires a 64-bits platform, 32-bits is not supported.

## Installing using ienv (recommended)

[ienv](https://gitlab.com/inko-lang/ienv) is the official version manager of
Inko. Using ienv you can easily install, remove, and use different versions of
Inko during development. ienv only supports Unix platforms. Using ienv, you can
install the latest version of Inko as follows:

```bash
ienv install latest
```

For more information, refer to the ["Using ienv"](/manual/ienv) guide.

## Installing using Homebrew

Inko is provided as a [default
formula](https://github.com/Homebrew/homebrew-core/blob/master/Formula/inko.rb)
in Homebrew, allowing you to install Inko as follows:

```bash
brew install inko
```

This formula is maintained by Homebrew and its contributors. For issues specific
to the formula (e.g. it doesn't work on a certain version of macOS), please
report issues in the [homebrew-core issue
tracker](https://github.com/Homebrew/homebrew-core/issues).

## Installing from Git

First clone the Git repository:

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
