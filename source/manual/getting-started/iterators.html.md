---
title: Iterators
---

Iterators are used for iterating over the values of a collection, such as an
`Array` or `HashMap`. Typically a programming language will use one of two
iterator types:

1. Internal iterators: iterators where the iteration is controlled by a method,
   usually by executing some sort of callback (e.g. a block).
2. External iterators: stateful data structures from which you "pull" the next
   value, until you run out of values.

Both have their benefits and drawbacks. Internal iterators are easy to implement
and usually offer good performance. Internal iterators can not be composed
together (easily), they are eager (the method only returns once all values have
been iterated over), making it harder (if not impossible) to pause and resume
iteration later on.

External iterators do not suffer from these problems, as control of iteration is
given to the user of the iterator. This does come at the cost of having to
allocate and mutate an iterator, which can sometimes lead to worse performance
when compared with internal iterators.

## Iterators in Inko

Inko primarily uses external iterators, but various types will allow you to use
internal iterators for simple use cases, such as just traversing the values in a
collection. For example, we can iterate over the values of an `Array` by sending
`each` to the `Array`:

```inko
import std::stdio::stdout

[10, 20, 30].each do (number) {
  stdout.print(number)
}
```

We can also do this using external iterators:

```inko
import std::stdio::stdout

[10, 20, 30].iter.each do (number) {
  stdout.print(number)
}
```

Using external iterators gives us more control. For example, we can simply take
the first value (skipping all the others) like so:

```inko
let array = [10, 20, 30]

array.iter.next # => 10
```

Because external iterators are lazy, this would never iterate over the values
`20` and `30`.

## Implementing iterators

Implementing your own iterators is done in two steps:

1. Create a separate object for your iterator, and implement the
   `std::iterator::Iterator` trait for it.
2. Define a method called `iter` on your object, and return the iterator created
   in the previous step. If an object provides multiple iterators, use a more
   meaningful name instead (e.g. `keys` or `values`).

To illustrate this, let's say we have a very simple `LinkedList` type that (for
the sake of simplicity) only supports `Integer` values. First we define an
object to store a single value, called a `Node`:

```inko
object Node {
  def init(value: Integer) {
    let @value = value

    # The next node can either be a Node, or Nil, hence we use `?Node` as the
    # type. We specify the type explicitly, otherwise the compiler will infer
    # the type of `@next` as `Nil`.
    let mut @next: ?Node = Nil
  }

  def next -> ?Node {
    @next
  }

  def next=(node: Node) {
    @next = node
  }

  def value -> Integer {
    @value
  }
}
```

Next, let's define our `LinkedList` object that stores these `Node` objects:

```inko
object LinkedList {
  def init {
    let mut @head: ?Node = Nil
    let mut @tail: ?Node = Nil
  }

  def head -> ?Node {
    @head
  }

  def push(value: Integer) {
    let node = Node.new(value)

    @tail.if true: {
      @tail.next = node
      @tail = node
    }, false: {
      @head = node
      @tail = node
    }
  }
}
```

With our linked list implemented, let's add the import necessary to implement
our iterator:

```inko
import std::iterator::Iterator
```

Now we can create our iterator object, implement the `Iterator` trait for it,
and define an `iter` message for our `LinkedList` object:

```inko
# Iterator is a generic type, and in this case takes a single type argument: the
# type of the values returned by the iterator. In this case our type of the
# values is `Integer`.
object LinkedListIterator impl Iterator!(Integer) {
  def init(list: LinkedList) {
    let mut @node: ?Node = list.head
  }

  # This will return the next value from the iterator, if any.
  def next -> ?Node {
    let node = @node

    @node.if_true {
      @node = @node.next
    }

    node
  }

  # This will return True if a value is available, False otherwise.
  def next? -> Boolean {
    @node.if true: {
      True
    }, false: {
      False
    }
  }
}

# Now that our iterator object is in place, let's reopen LinkedList and add the
# `iter` method to it.
impl LinkedList {
  def iter -> LinkedListIterator {
    LinkedListIterator.new(self)
  }
}
```

With all this in place, we can use our iterator like so:

```inko
let list = LinkedList.new

list.push(10)
list.push(20)

let iter = list.iter

stdout.print(iter.next.value) # => 10
stdout.print(iter.next.value) # => 20
```

If we want to (manually) cycle through all values, we can do so as well:

```inko
let list = LinkedList.new

list.push(10)
list.push(20)

let iter = list.iter

{ iter.next? }.while_true {
  stdout.print(iter.next.value) # => 10, 20
}
```

Since the above pattern is so common, iterators respond to `each` to make this
easier:

```inko
let list = LinkedList.new

list.push(10)
list.push(20)

let iter = list.iter

# Because of a bug in the compiler (https://gitlab.com/inko-lang/inko/issues/117)
# we need to manually annotate the block's argument for the time being.
iter.each do (node: Node) {
  stdout.print(node.value) # => 10, 20
}
```
