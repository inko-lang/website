---
title: Packages
description: A collection of Inko packages.
layout: packages
---

## Adding a package

To add a package, first create a GitHub repository for your package. While
Inko's package manager supports the use of any Git repository (e.g. one hosted
on GitLab), the above list is populated using GitHub repositories _only_.

Next, add a short description to your repository. This will be used as the
package description.

Package versions are just Git tags in the format `vX.Y.Z`, so make sure to push
at least a single tag.

Once this is done, fork the [Inko website
repository](https://github.com/inko-lang/website) and add your package to
`data/packages.yml` (see the existing entries for more details), then submit a
pull request with these changes. Once merged, it may take several days for the
package to show up on this page.
