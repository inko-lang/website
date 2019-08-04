---
title: "Inko progress report: July 2019"
date: 2019-08-04 13:51:20 UTC
---

Starting this month we will be sharing monthly updates on the progress made on
Inko, starting with July 2019. Using these progress reports we hope to give
better insight in the development process, and to give sponsors better insight
into what their donations are used for.

<!-- READ MORE -->

July has been a bit of a chaotic month. Originally, the plan was to focus on
porting over Inko's parser from Ruby to Inko. Along the way we realised we also
needed to focus on other tasks, such as improving our continuous integration
pipeline for Windows, and deal with sudden socket test failures for Linux. We
also realised that to make the parser simpler, we have to make several syntax
changes that we are not quite sure about just yet.

## Table of contents
{:.no_toc}

* TOC
{:toc}

## Changes to Inko's syntax and its parser

Let's start with the original goal: porting over the parsers. Inko's grammar is
an [LL(1)][ll-1] grammar. In short, this means source code is parsed left to
right, and lookaheads are limited to a single token at a time. The parser used
by the Ruby compiler is a hand-written recursive descent parser. The Ruby parser
was not written to be a production-ready parser, instead it's meant to get the
job done fast so we could focus on other parts of the compiler.

Instead of porting the parser as-is, we wanted to write a production-ready
parser, and give some parts of the syntax some extra thought. By rethinking some
parts of the syntax we hop to be able to simplify the parser, and to make it
easier for developers to read and understand Inko code. For example, [you can now
define static methods][static-methods]. While this did not necessarily make the
parser easier to write, it did allow us to clean up various parts of the
standard library. A bigger change is how attributes are defined in an object.
In versions before the upcoming 0.5.0 release, objects and their attributes were
defined as follows:

```inko
object Person {
  def init(name: String, age: Integer) {
    let @name = name
    let @age = age
  }
}
```

We originally chose this approach so you would not have to explicitly define the
attribute types, instead the compiler could infer them based on the values
assigned to the attributes. To make sure the compiler was able to find all
attribute definitions, it required you to define them in the `init` method.
This approach is rather fragile. For example, one could conditionally define
attributes like so:

```inko
object Person {
  def init(name: String, age: Integer) {
    let @name = name

    some_condition.if_true {
      let @age = age
    }
  }
}
```

Here the compiler would not be aware that `@age` might not always be defined,
which could leak to unexpected runtime errors. Instead of trying to come up with
clever ways of handling these kind of cases, we decided to change the syntax so
that you have to define attributes in the body of an object like so:

```inko
object Person {
  @name: String
  @age: Integer

  def init(name: String, age: Integer) {
    @name = name
    @age = age
  }
}
```

This approach turned out to not be nearly as verbose as we feared, and allows
the compiler to assert that all attributes are assigned to when creating an
object.

### Casting optional types

Another syntax change is the new syntax for the "not Nil" operator. Inko has
support for optional types, and sometimes you know a value is not Nil and want
to change the type from `?T` (an optional `T`) to just `T`. Inko allowed you to
do this using the `*` prefix operator like so:

```inko
let number: ?Integer = 10

*number
```

This prefix operator proved difficult to parse, so we replaced it with the `!`
postfix operator, which is easier to parse. This means that you now have to
write the following instead:

```inko
let number: ?Integer = 10

number!
```

### Removal of array and hash map literals

A potential big change we are considering is the removal of array and hash map
literals. Arrays are created using square brackets, such as `[10, 20, 30]`. Hash
map literals use the syntax `%[key: value]`, which is taken from Elixir. While
some languages use curly braces (e.g. `{key => value}` in Ruby), Inko already
uses these for closures. We could have used the syntax `[key: value]`, but this
would require the parser to perform a lookahead to determine if it's parsing an
array or a hash map. This syntax would also make the meaning of `[]` ambiguous:
is it an empty array, or an empty hash map? We could use `[:]` for empty hash
maps, but this would further complicate the parser.

Square brackets are also used for accessing indexes and hash map keys, using the
`[]` and `[]=` methods:

```inko
let numbers = [10, 20]

numbers[10]
```

The use of brackets for different purposes makes it difficult to parse. For
example, what is the following supposed to mean?:

```inko
foo [10]
```

Are we sending the message `foo` and pass it the argument `[10]`, or are we
trying to access index 10 from the result of `foo`? Some of these ambiguities
could be resolved by looking at the token that precedes the `[`, but this might
not be able to cover all possible cases.

The solution we are considering is to remove support for array and hash map
literals, turn `:` into an operator, and just use `Array.new` and `HashMap.new`
(which we are renaming to `Map.new`):

```inko
Array.new(10, 20, 30)        # same as [10, 20, 30]
HashMap.new('name': 'Alice') # same as %['name': 'Alice']
```

This may be a bit more verbose, but comes with several benefits:

1. It simplifies both the lexer and parser.
1. It makes it clear what type you are dealing with, in particular for hash maps
   since the syntax `%[key: value]` is uncommon.
1. It allows us to add support for tuples and other built-in data structures in
   the future, without having to change the syntax.

We thought about using factory functions so you can write `Array(10, 20, 30)`
instead of `Array.new(10, 20, 30)`, but we feel it's not much better than using
`Array.new(10, 20, 30)` for these simple use cases.

This brings us to a type that Inko does not have: tuples. If we were to turn `:`
into an operator, it would have to return a tuple of two values: the receiver
(the key in case of hash maps), and the argument (the value). Inko does not have
tuples, and probably won't support them for a while. This creates a bit of a
dilemma: we don't want to add support for tuples for now, but we also don't want
to introduce some kind of "Pair" type that is used just for creating hash maps.

The reason that we don't want to introduce tuples for now is that they either
require support for variadic type parameters, or you have to define a tuple type
for every number of fields (Tuple1, Tuple2, Tuple3, etc). Using separate types
would also require some syntax changes, allowing you to write something like
`(10, 20)` instead of `Tuple2.new(10, 20)`.

With that said, we will probably go with the `Pair` approach and maybe give it a
better name. After all, it's better to have a solution that works (even if it's
not pretty), than to have no solution at all.

## Continuous integration for Windows

To run tests on Windows, we used [AppVeyor][appveyor]. Working with AppVeyor has
always been a bit difficult, as its approach to building and testing changes is
quite different from GitLab CI. In GitLab you can define different stages, and
the pipeline moves to the next stage if all previous stages have passed.
AppVeyor has no concept of stages, and all builds run at (more or less) the same
time. As part of our release pipeline we have a CI job that updates various
release related files, something that must happen after all packages have been
built and uploaded to Amazon S3. Due to AppVeyor being an external service and
not having the concept of stages, there was no way for the release job to run
after AppVeyor finished, meaning we could not reliably provide Windows packages.

To resolve this long standing issue, we have been looking into setting up GitLab
Runner on Windows. In the past this was a problem as there was no support for
using Windows containers, requiring the use of either VirtualBox or GitLab's
(insecure) shell executor. GitLab now supports using Docker on Windows to run
Windows containers, allowing us to move away from AppVeyor.

Moving over turned out to be far more difficult than anticipated. The first
challenge is the costs: while Linux servers come cheap, Windows servers tend to
be expensive. After looking around we settled for [Hetzner][hetzner], which
offers Windows 2016 servers for about €50/month. While expensive for a project
that makes no money, it's small enough that it could be covered by donations.

Having set up the server at Hetzner, we spent a good week or so trying to get
things up and running. When doing so, we ran into a variety of problems:

1. When using the default VirtIO NIC, Windows would start to misbehave after
   installing Docker. Network speeds were low, Windows could no longer find the
   license, and certain programs (e.g. the Windows control panel) would not
   start up. We had to change the NIC type to work around this.
1. GitLab Runner does not officially support Windows 2016, so we had to [patch
   it to support Windows 2016][gitlab-runner-2016].
1. Building a Docker image containing all the necessary dependencies took
   _hours_. Even after running for over 24 hours it still did not finish
   building the image (the total size including the Windows base image is around
   5GB).
1. Windows 2016 took a long time installing updates, often failing during
   the installation procedure. This required us to retry the process several
   times before it would succeed.

The Docker build times were the biggest problem. While we anticipated it would
take a while to build images, we did not expect it would take this long. The
image we were trying to build would be between 5GB and 6GB. Most of that is used
by the Windows Server Core base image, followed by about 1GB of dependencies,
most of which was used by [MSYS2][msys2]. Despite the various optimisations we
applied to our Dockerfile, the build process would run for hours. After 24 hours
or so we would stop the job, then try a different approach to reduce the image
size.

During this time we found out that the root cause is Docker trying to compress
the layers produced by our `RUN` commands, and that this can be slow when
compressing large layers. We were not the first ones to run into this issue, as
[users of Docker have been asking for a solution since 2013][moby-1266].

After trying to get things to work for over a week, we gave up on Windows Server
2016, and moved to a Windows Server 2019 server hosted at [TransIP][transip].
Hetzner does not yet offer Windows Server 2019, so we had to move elsewhere
(they did refund us the full amount we had paid, which was just under €80).

By moving to Windows 2019 we would no longer have to patch GitLab Runner as it
support Windows 2019, and we hoped that perhaps the build timing problems would
be less severe. While we did not run into any issues with the NIC or Windows
updates, we did run into the same problem with building images taking a long
time.

One interesting discovery we made is that by default the network on this Windows
2019 server was incredibly slow, even for local traffic. We managed to solve
this by disabling Received Segment Coalescing using the following Powershell
command:

    Disable-NetAdapterRsc *

You can read a bit more about this in [this Reddit thread][reddit-rsc].

This had a huge impact on the network speed, though it did not speed up the
process of building large Docker images. It did greatly reduce the time it takes
to send large files and folders to the Docker daemon. During all this we found
out that while large layers produced by a `RUN` command effectively cause the
build to get stuck, Docker performs much better when using `COPY` to copy over
large files and folders. With network speeds being back to normal, this gave us
an idea: instead of setting up all dependencies from scratch when building the
image, we do this for the smaller dependencies such as Ruby and Rust. For MSYS2
we take the following approach:

1. Copy the host machine's MSYS2 installation into the Docker build context
   directory.
1. Send the directory to the Docker daemon.
1. Use Docker's `COPY` command to copy the MSYS installation into the container.

Using this approach we are able to build a self-contained Docker image in
about 20 minutes. This is still a long time, but far better than what it took
before.

We did consider mounting the MSYS2 installation read-only in the container, but
this did not work as MSYS2 requires write access to various files and folders.
Mounting the installation as writable could allow jobs to poison the
installation.

Along the way we ran into several issues with GitLab Runner as well. For
example, [when using Powershell to execute an unknown command, GitLab will
report the job as having succeeded][runner-3415]. There are also [other cases
where the exit status is not read properly][runner-3194]. We are also still
looking into an issue where GitLab Runner claims a cache URL is not configured
when using S3 for caching builds, even though the URL _is_ configured.

While we are getting closer to getting GitLab Runner to work on Windows using
the images we need, it has been a frustrating experience. Once everything is up
and running we will be able to provide binaries for Windows. These binaries are
compiled using MingW GCC using the GNU ABI, allowing you to use them without
having to install MSYS2. In the future we aim to make this even easier by
rewriting ["ienv"][ienv] (Inko's version manager) in Rust, instead of using
Bash. Using Rust would allow one to use ienv without having to install Bash,
which on Windows would require some sort of Unix emulation layer (MSYS2, Windows
Subsystem for Linux, etc). For now this is not (yet) a priority, so hang tight!

## Dependency scanning in CI

In commit [59a1ae][dep-scanning] we fixed our security scanning CI job, which
was not implemented properly. With this job fixed, we can see if any of the VM's
dependencies have any security issues, and how to resolve these issues, powered
by [cargo-audit][cargo-audit]. Since GitLab does not support Rust/cargo-audit
out of the box, we had to provide support ourselves.  We achieved this by
converting cargo-audit's output into a format understood by GitLab, [using a
simple Ruby script][audit.rb]. While this is not a user facing change, it has
already proven useful to us by alerting us of two security issues in the last
month.

## Donations through Open Collective

In July we [set up an account on Open Collective][open collective], allowing
those interested in Inko to donate money on a recurring basis. The first goal is
to collect enough donations to cover our infrastructure costs. After that we
hope to (one day) receive enough donations that Yorick (the author of Inko) can
work on Inko at least one day per week, and maybe even more days per week.

If you are interested in Inko and would like to sponsor its development, please
donate to Inko on [Open Collective][open collective]. Donations start at
€5/month, and all backers and sponsors will be displayed on the
[Sponsors](/sponsors) page. Those donating more than €100/month will also have
their logo displayed on the homepage.

## Plans for August

For August we aim to make a decision about array and hash map literals, complete
the work on porting the parser to Inko, release Inko 0.5.0, and start working on
porting over the compiler to Inko.

[ll-1]: https://en.wikipedia.org/wiki/LL_parser
[static-methods]: https://gitlab.com/inko-lang/inko/commit/f86eb0b091e3c0ffdbda2d7387f36b9ae091501e
[appveyor]: https://www.appveyor.com/
[hetzner]: https://www.hetzner.com/
[gitlab-runner-2016]: https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/1508
[msys2]: https://www.msys2.org/
[transip]: https://www.transip.nl/
[moby-1266]: https://github.com/moby/moby/issues/1266
[runner-3415]: https://gitlab.com/gitlab-org/gitlab-runner/issues/3415
[runner-3194]: https://gitlab.com/gitlab-org/gitlab-runner/issues/3194
[reddit-rsc]: https://www.reddit.com/r/sysadmin/comments/c9a005/server_2019_vm_slow_network_performance_due_to_rsc/
[ienv]: https://gitlab.com/inko-lang/ienv
[dep-scanning]: https://gitlab.com/inko-lang/inko/commit/59a1aeda2c5758451b3cc9e3cd4ba9b72ec8a479
[cargo-audit]: https://crates.io/crates/cargo-audit
[audit.rb]: https://gitlab.com/inko-lang/inko/blob/94e22f5cf9525c1fed071b821f9c4ba3573f1831/scripts/audit.rb
[open collective]: https://opencollective.com/inko-lang
