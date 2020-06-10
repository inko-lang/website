---
title: Introducing the Inko version manager
date: 2018-07-30 19:00:00
keywords:
  - inko
  - version manager
  - ienv
description: Introducing the Inko version manager.
---
<!-- vale off -->

Inko now has an official version manager, making it much easier to install Inko
in a development environment.

<!-- READ MORE -->

The version manager, called "ienv", can be used to manage Inko installations in
a development environment. This makes it _much_ easier to install a new version
of Inko, compared to building from source. For example, to install version 0.1.0
of Inko all you need to do is run the following:

```bash
ienv install 0.1.0
```

Removing a version is also simple:

```bash
ienv remove 0.1.0
```

ienv is a very simple version manager, written in Bash. Currently it only
officially supports Linux, but supporting BSD and Mac OS is planned. For Windows
we currently don't offer any support.

For more information, refer to one of the following resources:

* The [ienv repository](https://gitlab.com/inko-lang/ienv)
* The [ienv manual page](/manual/ienv/)
* The updated [installation guide](/manual/install), which includes details on
  how to install ienv.
