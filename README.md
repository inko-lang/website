# README

This repository contains the source code for the [Inko
website](https://inko-lang.org/).

## Requirements

- Inko 0.17.0 or newer

## Development

Install the necessary packages:

```bash
inko pkg sync
```

Build the website:

```bash
inko run
```

If you want to start a server and automatically build the website upon any
changes, run the following:

```bash
make watch
```

This requires [inotify-tools](https://github.com/inotify-tools/inotify-tools)
and [Python 3](https://www.python.org/) to be installed.

## License

All source code in this repository is licensed under the Mozilla Public License
version 2.0, unless stated otherwise. A copy of this license is found in the
file "LICENSE".
