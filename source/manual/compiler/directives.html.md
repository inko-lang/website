---
title: Directives
---

## Table of contents
{:.no_toc}

1. TOC
{:toc}

## Introduction

Inko allows you to set certain compiler configuration options directly in the
source code. These configuration options are known as "compiler directives".
While these directives are available, they are not part of the public API and as
such should not be used directly.

## Setting directives

Directives can be set by using the syntax `![DIRECTIVE: VALUE]`. For example:

```inko
![import_bootstrap: false]
```

## Available directives

### import_prelude

A boolean (true/false) that enables/disables the automatic importing of the
`core::prelude` module.

This directive is enabled by default.

### import_bootstrap

A boolean (true/false) that enables/disables the automatic importing of the
`core::bootstrap` module.

This directive is enabled by default.

### import_globals

A boolean (true/false) that enables/disables the automatic importing of the
`core::globals` module.

This directive is enabled by default.

### define_module

A boolean (true/false) that enables/disables the automatic defining of a module.
If disabled, the code of a module is evaluated in the context of the `Inko`
object.

This directive is enabled by default.
