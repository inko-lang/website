---
author: Yorick Peterse
title: Inko 0.8.1 released
date: "2020-10-04 18:00:00 UTC"
---

Inko 0.8.1 has been released, featuring a new approach for running Inko
bytecode, fewer dependencies, and a simplified build and installation process.

<!-- READ MORE -->

## Table of contents
{:.no_toc}

* TOC
{:toc}

For the full list of changes, take a look at
[the changelog](https://github.com/inko-lang/inko/blob/5440b4e4c552b4f41b9e03cd1bbd3c1b44ace926/CHANGELOG.md#080---october-03-2020).

If you would like to support the development of Inko, please [donate to Inko on
Open Collective](https://opencollective.com/inko-lang) or via [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse/).

**NOTE:** this release makes changes to the build system. If you are using
[ienv](https://gitlab.com/inko-lang/ienv) to manage Inko installations, you need
to first upgrade ienv before you can install 0.8.1.

## Reusing garbage collection threads

Inko performs parallel garbage collection, meaning multiple threads are used to
garbage collect a process. Before version 0.8.1, Inko would spawn these threads
whenever garbage collection was performed. Starting with 0.8.1, these threads
are spawned the VM starts and reused. This reduces the total time spent garbage
collecting processes.

See merge request <https://gitlab.com/inko-lang/inko/-/merge_requests/97> for
more information.

## Bytecode files have been replaced with bytecode images

Before version 0.8.1, Inko's compiler would produce a bytecode file for every
source file. The VM in turn would load these bytecode files whenever a module
had to be imported. Starting with Inko 0.8.1, the compiler produces a single
bytecode file called a "bytecode image". This file contains all the bytecode
necessary to run your application, much like a
[JAR](https://en.wikipedia.org/wiki/JAR_(file_format)). The VM in turn no longer
loads individual bytecode files on demand, instead it runs this bytecode image.

This reduces the amount of disk IO necessary to load modules, and allows the VM
to parse modules in this bytecode image in parallel. Distribution is also made
easier, as you only need to distribute a single bytecode file.

Parallel module parsing is useful for both small and large projects, and helps
keep the startup time as low as possible. For example, running an empty Inko
program only needs about 5 milliseconds. For comparison, an empty Ruby 2.6.6
program needs at least 45 milliseconds, and an empty Python 3.8.5 program needs
at least 15 milliseconds.  Of course empty programs are not useful, but this
gives an idea of the base startup overhead.

See merge request <https://gitlab.com/inko-lang/inko/-/merge_requests/98> for
more information.

## Renaming of Duration methods

The following methods of the `std::time::Duration` type have been renamed:

| Old name                 | New name
|:-------------------------|:---------------------
| Duration.as_seconds      | Duration.to_seconds
| Duration.as_milliseconds | Duration.to_milliseconds
| Duration.as_microseconds | Duration.to_microseconds

## Revamped build system

The process for building Inko from source has been cleaned up, simplified, and
broken into two stages: building and installing; instead of everything being
mixed into a single stage. Building Inko is now a matter of running `make
build`, while installing is a matter of `make install`.

The building and installation process can be customised by setting the `PREFIX`
and/or `DESTDIR` variables. The `PREFIX` variable specifies the base directory
to load files from at runtime, and also acts as a default for `DESTDIR`. The
`DESTDIR` variable specifies the directory to move files into during the
installation process. This can be a different directory from the `PREFIX`
directory. This is useful when building packages for a package manager, as these
are typically installed into a chroot/jail of some sort before being packaged.

Development builds are also made easier. For example, to build the VM for
developing Inko itself you'd run:

```bash
make vm/release DEV=1
```

This builds the VM such that it loads all its necessary files from your local
Git clone of the Inko repository.

If you are using ienv, you must first upgrade to the latest ienv version before
you can install 0.8.1. Assuming you have ienv installed in
`~/.local/share/ienv`, you can upgrade as follows:

```bash
cd ~/.local/share/ienv
git pull origin master
```

Next you need to clean up any caches ienv may have produced:

```bash
ienv clean
```

You can then install 0.8.1 as follows:

```bash
ienv install 0.8.1
```

Once upgraded to the latest version of ienv, older versions of Inko can't be
installed, won't work anymore, and won't show up in the output of `ienv known`.

Combined with the reduced number of dependencies (more on this below), you can
now build Inko on Windows using the Visual Studio build tools. This process is
still a little involved and undocumented, but it comes down to the following
steps:

1. Install the Visual Studio 2017 build tools, and enable the C++/CLI feature
1. Install Rust, and the `stable-msvc` toolchain using `rustup toolchain install
   stable-msvc`
1. Start a x64 Visual Studio developer prompt, and navigate to your local copy
   of Inko's source code
1. Run `set RUSTFLAGS=-C target-feature=+aes`
1. Run `rustup run stable-msvc cargo build --release`

If all went well, you should now have an `inko.exe` in `./target/release`.

We aim to make this process easier and documented in the future.

## No more pre-compiled packages

Starting with 0.8.1, we no longer provide pre-compiled packages for Linux, macOS
and Windows. We found this to complicate the release process too much, while
not bringing enough benefits to make this worth the effort. Instead, we will
focus our attention of getting Inko in package manager repositories. For more
details, refer to [this issue](https://github.com/inko-lang/inko/issues/287).

## Revamped CLI

Inko now only exposes a single executable to your PATH: `inko`. Before version
0.8.1, Inko would also expose the executables `ivm`, `inkoc`, and `inko-test`.

To run a script, you now use `inko example.inko` or `inko run example.inko`. You
can also run scripts directly using the `-e/--eval option`. For example:

```bash
inko run -e "import std::stdio::stdout
stdout.print('hello')"
```

If you just want to compile a program, you'd run `inko build example.inko`. This
will then save the resulting bytecode in `./example.ibi`.

If you want to run unit tests from a `./tests/test` directory, you'd run `inko
test`.

## Fewer dependencies

Inko depends on [libffi](https://sourceware.org/libffi/) so Inko source code can
interact with C libraries. Before version 0.8.1, libffi was always built from
source and required automake, autoconf, libtool, Make, and libclang. On Linux
these dependencies can be installed using a package manager, but on other
platforms this may not be as easy. For example, macOS ships with clang but not
libclang. You can install LLVM (and thus libclang) using
[Homebrew](https://brew.sh/), but this installation is not available in your
PATH by default; requiring extra steps before the installation is ready for use.

Starting with Inko 0.8.1, the LLVM and libclang dependencies are no longer
necessary. You can now also choose to use to use the libffi installation
provided by your system; if there is any. When using the system libffi
installation, automake, autoconf, and libtool are not necessary.

To build Inko such that it uses your system's libffi installation, run the
following:

```bash
make build FEATURES='libinko/libffi-system'
sudo make install
```

This will then install Inko relative to `/usr`, and place the executable at
`/usr/bin/inko`.

## Faster hashing using AES-NI

Inko uses hashing in a variety of places. To speed this up, Inko now makes use
of the [aHash](https://github.com/tkaitchuck/ahash/) crate, and compiles with
AES-NI support. Virtually all CPUs since 2010 or so have AES-NI support, so no
further changes should be necessary.

In the odd event of your CPU not supporting AES-NI, you need to build the VM
manually instead of using Make. You can do so by running `cargo build --release`
in the root directory of the Inko project. If you also want to use the system
libffi installation, you need to run the following:

```bash
cargo build --release --features libinko/libffi-system
```

## Documentation changes

We are working on a new documentation setup using
[mkdocs](https://www.mkdocs.org/). Until this work is completed, the current
documentation may be out of date in several places. The new documentation setup
aims to make it easier to find documentation, contribute documentation, and
offers richer formatting features (e.g. tips and warnings).

Progress on this is tracked in merge request
<https://gitlab.com/inko-lang/inko/-/merge_requests/103>.

## Arch Linux packages

If you are using [Arch Linux](https://www.archlinux.org/), you can now install
Inko using the AUR. Two packages are provided by the AUR:
[inko](https://aur.archlinux.org/packages/inko/), and
[inko-git](https://aur.archlinux.org/packages/inko-git). The "inko" package
installs the latest stable release of Inko, while the "inko-git" package
installs Inko from Git.

If you are using [yay](https://aur.archlinux.org/packages/yay/) as your AUR
helper of choice, you can install these packages as follows:

```bash
yay -S inko-git    # To install from Git
yay -S inko        # To install the latest stable version
```

## Homebrew formula

The Homebrew formula for Inko has been updated to install 0.8.1. Homebrew users
can install this new version as follows:

```bash
brew update
brew install inko
```
