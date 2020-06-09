---
title: Using ienv
---
<!-- vale off -->

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

[ienv](https://gitlab.com/inko-lang/ienv) is Inko's official version manager,
written in Bash.

## Installation

The easiest way to install ienv is to clone its Git repository:

    git clone https://gitlab.com/inko-lang/ienv.git ~/.local/share/ienv

Now you need to add the `ienv` executable to your PATH for your shell of choice.
For Bash you would add the following to `~/.bashrc`:

    export PATH="${PATH}:$HOME/.local/share/ienv/bin"

For [Fish](https://fishshell.com/), add the following to
`~/.config/fish/config.fish`:

    set -x PATH $PATH $HOME/.local/share/ienv/bin

Now that ienv is installed, we can install Inko.

## Usage

### Install a version

To install a version of Inko, run the `install` command:

```bash
ienv install 0.6.0
```

Whenever possible, ienv will use pre-compiled packages. This removes the need
for having to compile the virtual machine, which in turn makes the installation
procedure easier and faster. If no pre-compiled package is available, ienv will
install Inko from source instead.

### Change the default version

ienv will not automatically set a version to use for you, instead you need to do
so manually. This can be done by running the following

```bash
ienv default 0.6.0
```

This will set `0.6.0` as the default version.

### remove a version

To remove a version:

```bash
ienv remove 0.6.0
```

### List all installed versions

To list all installed versions:

```bash
ienv list
```

### List all known versions

To list all available versions:

```bash
ienv known
```

### Cleaning up temporary data

To remove any temporary data (e.g. the manifest and any downloaded packages):

```bash
ienv clean
```

### Running commands using ienv

Running an Inko command using a specific version:

```bash
ienv run 0.6.0 -- ivm --version
```

If you have configured a default version using `ienv default`, then you can
leave out the version when using the `run` command:

```bash
ienv run -- ivm --version
```

### Updating ienv

Updating ienv itself:

```bash
cd ~/.local/share/ienv
git pull origin master
```

If you installed ienv in a different location, make sure to change the path used
above to your ienv installation path.

More information about ienv can be obtained by running `ienv --help`.

## Directory overrides

ienv can automatically use a directory specific version of Inko. To specify a
directory specific version, create a file called `inko-version` and add the
desired version to it. For example:

```bash
echo '0.6.0' > inko-version
```

You can then use the `run` command as follows to use the directory override:

```bash
ienv run -- ivm --version
```

ienv _only_ supports directory for the _current_ working directory, it will
_not_ examine any parent directories.

## Configuration

ienv can be configured using various environment variables. These variables are
best set in a configuration file for your shell, such as `~/.bashrc` or
`~/.config/fish/config.fish`.

### IENV_MIRROR

The base URL of the mirror to use for downloading packages. Defaults to
<https://releases.inko-lang.org/inko>.

## Directories and files

ienv adheres to the [XDG base directory specification][xdg]. Specifically, it
uses the following directories and files:

* `$XDG_DATA_HOME/ienv/installed`: the directory containing installed versions.
* `$XDG_CONFIG_HOME/ienv`: the directory containing various configuration files.
* `$XDG_CACHE_HOME/ienv`: the directory containing temporary files, such as
  downloaded archives and a local copy of the package manifest.
* `$XDG_CONFIG_HOME/ienv/inko-version`: a simple text file containing the
  default version to use.

[xdg]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
