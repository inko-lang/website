---
author: Yorick Peterse
title: Inko now supports stable Rust
date: 2018-08-02 18:00 UTC
keywords:
  - inko
  - rust
  - stable
  - nightly
description: Inko now supports building using stable Rust.
---
<!-- vale off -->

With the release of [Rust 1.28][rust-1.28], Inko can now be built using stable
Rust, instead of requiring Rust nightly.

<!-- READ MORE -->

This means it's now much easier to install Inko, as stable Rust is typically
available in package managers, while nightly Rust usually is not.

When building using Rust stable, various nightly-only features are disabled
automatically. If performance is important, we _highly_ recommend using Rust
nightly, as this will greatly improve the performance of the garbage collector.
The garbage collector uses prefetching as described in the paper ["Effective
Prefetch for Mark-Sweep Garbage Collection"][prefetch]. This can lead up to a
30% performance improvement, compared to disabling the use of prefetching.

Support for Rust stable is available starting with Inko 0.2.0, which can be
installed using [ienv][ienv] as follows:

```bash
ienv clean
ienv install 0.2.0
ienv default 0.2.0
```

If you already have 0.1.0 installed, you can remove it as follows:

```bash
ienv remove 0.1.0
```

Whenever possible, ienv will install precompiled packages that have the
nightly-only features enabled.

Support for stable Rust was added in the following commits:

* [ienv: Support building using stable Rust](https://gitlab.com/inko-lang/ienv/commit/b91e896cc9761beba6eb591a509fcc265fa27912)
* [inko: Support building on stable Rust ](https://gitlab.com/inko-lang/inko/commit/8cf6067428a4865b98c7dfb64eb46117c2f74263)
* [inko: Use std::alloc everywhere](https://gitlab.com/inko-lang/inko/commit/47e9f0fe3e8ad8f9ea8fe57e3a83f7c59b899500)
* [inko: Use std::alloc for immix::block](https://gitlab.com/inko-lang/inko/commit/443dfba376a6f50e54149a7b94b77b6871c4bb52)

[rust-1.28]: https://blog.rust-lang.org/2018/08/02/Rust-1.28.html
[prefetch]: http://users.cecs.anu.edu.au/~steveb/downloads/pdf/pf-ismm-2007.pdf
[ienv]: https://gitlab.com/inko-lang/ienv
