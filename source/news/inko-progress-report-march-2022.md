---
{
  "title": "Inko Progress Report: March 2022",
  "date": "2022-04-02 14:59:39 UTC"
}
---

## Type checking progress

The new type checker is complete, and is able to check Inko's standard library
without producing any errors or overlooking incorrect code. Testing is still
done manually at this stage, and this will probably remain so until our
mid-level IR is complete.

## Inko's mid-level intermediate representation

With the type checker fully implemented, we started working on Inko's mid-level
IR, or "MIR" for short. This IR is used for more advanced analysis (e.g.
ensuring a variable isn't used after it's moved elsewhere) and optimisations.
The IR is a graph based IR, with an instruction set that resembles the virtual
machine's instruction set.

Various operations that are implicit in the AST/syntax are explicit in MIR. For
example, you can pass an owned value to an argument that expects a reference,
and Inko will automatically pass the value as a reference then drop the owned
value after the call. The result is that code such as this:

```inko
fn foo(value: ref String) {
  ...
}

fn bar {
  foo("Alice")
}
```

Is the same as this:

```inko
fn foo(value: ref String) {
  ...
}

fn bar {
  {
    let _val = "Alice"

    foo(ref _val)
  }
}
```

In MIR, this translates to more or less the following:

```inko
fn foo(value: ref String) {
  ...
}

fn bar {
  let _v1 = "Alice"

  foo(ref _v1)
  drop(_v1)
}
```

When lowering the high-level IR/AST to MIR, we also apply other changes such as:

- Desugaring closures into classes
- Desugaring enum classes into regular classes
- Desugaring pattern matching into more primitive expressions (e.g. simple
  equality checks)
- Turning named arguments into positional arguments
- Constant folding constant definitions, meaning `let A = 10 + 5` is turned into
  `let A = 15`

Future optimisations we'll apply on MIR will include inlining, devirtualisation,
constant folding and propagation (inside method bodies), dead code elimination,
and more.

## Plans for April

In April we'll continue work on MIR, and we expect some of this work to carry
over into May. If you'd like to follow along with the progress made, we
recommend joining the [Matrix
channel](https://matrix.to/#/#inko-lang:matrix.org) or the `#inko` channel in
the [/r/ProgrammingLanguages Discord server](https://discord.gg/yqWzmkV). If
you'd like to support Inko financially, you can do so using [GitHub
Sponsors](https://github.com/sponsors/YorickPeterse).
