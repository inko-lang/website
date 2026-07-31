# README

This repository contains the source code for the [Inko
website](https://inko-lang.org/).

## Requirements

- Inko

## Development

Install the necessary packages:

```bash
sudo dnf install just rsync
```

Build the website:

```bash
just build
```

If you want to start a server and automatically build the website upon any
changes, run the following:

```bash
just watch
```

This requires [inotify-tools](https://github.com/inotify-tools/inotify-tools) to
be installed.

## License

All source code in this repository is licensed under the Mozilla Public License
version 2.0, unless stated otherwise. A copy of this license is found in the
file "LICENSE".
