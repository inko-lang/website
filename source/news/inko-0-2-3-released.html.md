---
author: Yorick Peterse
title: Inko 0.2.3 released
date: 2018-08-19 12:30:00 UTC
description: Inko 0.2.3 released
---
<!-- vale off -->

Inko 0.2.3 has been released.

<!-- READ MORE -->

This release is a fairly small release. For the most part this release includes
various changes related to publishing releases. One change worth discussing more
is the introduction of improved garbage collection performance when moving
objects.

The garbage collector divides the heap into one or more buckets. The young
generation has four buckets, while the mature generation only has a single
bucket. Prior to 0.2.3, the garbage collector would lock the source and target
buckets when moving objects. This means that only a single object can be
promoted or evacuated in parallel, which results in pretty poor garbage
collection performance.

With 0.2.3, bucket wide locking has been removed in favour of using atomic
operations in various places. This allows garbage collector threads to promote
and evacuate objects in parallel. Locking is still necessary when requesting a
new block from the global allocator, but this is only necessary once every 1020
objects, as one block can hold 1020 objects. This new setup results in a
performance improvement of about 2x compared to the old approach.

More information about these changes can be found in the merge request ["Use
atomic operations for allocating objects, and remove bucket wide locking"][mr-10].

The full list of changes can be found in the [CHANGELOG][changelog].

[mr-10]: https://gitlab.com/inko-lang/inko/merge_requests/10
[changelog]: https://gitlab.com/inko-lang/inko/blob/6bf7cfb086183aa7a0fdad2edb210cd6c1a4ec1e/CHANGELOG.md#023-august-19-2018
