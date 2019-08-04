---
title: Inko 0.4.1 released
date: 2019-05-15 00:24:34 UTC
description: Inko 0.4.1 has been released
---
<!-- vale off -->

Inko 0.4.1 has been released, fixing a bug that would occur when connecting to
to an address using the socket API.

<!-- READ MORE -->

This release includes a fix for connecting a socket to another socket. The way
connecting sockets was implemented could lead to a variety of different issues,
such as Inko trying to connect over and over again.

More information about the problem and fixes can be found in commit
[53675b][fix].

[fix]: https://gitlab.com/inko-lang/inko/commit/53675b7ae824d7bae5e701628044cc5580ee82ab
