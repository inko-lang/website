---
title: Inko Programming Language
created_at: 2018-07-09
tags:
  - inko
  - programming language
  - object oriented
  - concurrent
  - interpreted
description: >
  Concurrent and safe object-oriented programming, without the headaches.
---

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

This is a paragraph of text.

This text is **bold**, and this is _italic_. Here is an unordered list:

* Item 1
* Item 2
  * Sub item 1
  * Sub item 2
    * Sub sub item 1
    * Sub sub item 2

Here is a numbered list:

1. Item 1
1. Item 2
    1. Sub item 1
    1. Sub item 2
       1. Sub sub item 1
       1. Sub sub item 2

Here is block quote:

> Wow such quote, much content.

Here is a block of code, highlighted:

```inko
object Person {
  def init(name: String) {
    let @name = name
  }

  def name -> String {
    @name
  }
}
```
