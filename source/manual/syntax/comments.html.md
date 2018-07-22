---
title: Comments
---

Syntax:

```ebnf
any = ? Any character ?;
eol = ? The end of a line ?;

comment         = line-comment | doc-comment | mod-doc-comment;
line-comment    = '#',  { any }, eol;
doc-comment     = '##', { any }, eol;
mod-doc-comment = '#!', { any }, eol;
```

There are three types of comments:

1. Regular comments
1. Documentation comments
1. Module documentation comments

Multiple lines starting with the same kind of comment, without any leading
characters, should be treated as a single comment. For example, this is a single
comment:

```inko
# This is the first line of the comment.
# This is the second line of the comment.
```

Here both lines are treated as a single comment. Empty lines between comments
are ignored, meaning the following is still treated as a single comment:

```inko
# This is the first line of the comment.

# This is the second line of the comment.
```

The following example shows two separate comments:

```inko
# This is the first comment.
10 # This is a second, separate comment.
```

## Regular comments

Regular comments start with a `#`, and stop at the end of the line.

Example:

```inko
# This is a regular comment.
```

## Documentation comments

Documentation comments are used for documenting types and methods. These type of
comments start with `##`, and stop at the end of the line.

Example:

```inko
## This is a documentation comment.
```

## Module documentation comments

Module documentation comments are used for documenting modules. These type of
comments start with `#!`, and stop at the end of the line.

Example:

```inko
#! This is a module documentation comment.
```
