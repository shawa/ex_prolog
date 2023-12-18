# `ex_prolog`

`ex_prolog` is an experiment to build a deeply embedded DSL for Prolog in Elixir. The general idea is that if Erlang came from Prolog, and their ASTs are similar, and Elixir and Erlang are basically the same thing, then the leap from Prolog to Elixir won't be too outrageous to make. I don't think it is!

At the moment, this requires [SWI Prolog](https://www.swi-prolog.org/) to be on the host machine.

So far I've got together some pretty neat ideas:

## `defprolog` macro

`defprolog` lets you use Elixir syntax to write Prolog code to be read by SWI-Prolog in Elixir. For example:

```elixir
defprolog do
  pairs(x, y) <- [
    member(x, [1, 2, :b]),
    member(y, [9, 8, :a])
  ]

  colleague(:joe, :mike)
  colleague(:mike, :robert)

  colleague(x, y) <- [
    x != y,
    colleague(x, z),
    colleague(y, z)
  ]

  as() ~> []
end
```

This expands into function `__prolog__/0`, which returns pretty(ish)-printed Prolog code (more on this later). Note how variables are upcased as expected, atoms are transformed, and the operators are remapped. DCGs are _nearly_ supported, mapping `~>` to `-->`.

```prolog
% ex_prolog: Elixir.ExProlog.Example

pairs(X, Y) :-
  member(X, [1, 2, b]),
  member(Y, [9, 8, a]).

colleague(joe, mike).

colleague(mike, robert).

colleague(X, Y) :-
  X \= Y,
  colleague(X, Z),
  colleague(Y, Z).

as() --> [].
```

## `query/1` macro

`query/1` accepts a single `call` as its argument, and returns a query suitable for SWIPL. Think of a `call` just like a [compound term](https://www.metalevel.at/prolog/data):

```elixir
iex(0)> require ExProlog.Prolog
ExProlog.Prolog
iex(1)> Prolog.query(person(x))
"person(X)."
iex(2)> Prolog.query(1 <= 2)
"1 =< 2."
```

This is a bit out of the ordinary, as for example we never defined `person/1` or `x` anywhere.

In any case, the real fun in building an interop is in the _interop_, so we can also pin variables to pass them through:

```elixir
iex(3)> xs = [1, 2, 3, 4]
[1, 2, 3, 4]
iex(4)> query(length(^xs, l))
"length([1, 2, 3, 4], L)."
```

You can use the pin operator in `defprolog` too!

## SWIPL Interop

Where this all comes together is by stuffing it all down a [Port](https://hexdocs.pm/elixir/1.15.7/Port.html) to a running instance of SWI-Prolog.

`ExProlog.SWIPL` starts up, and optionally consults a list of **Elixir Modules** to populate the database. It expects them to export that same `__prolog__/0` function we saw earlier.

`call/1` and `all/1` take a Prolog query and run it, attempting to parse out the results back into Elixir AST. The difference between the two is that `call` assumes the query has only one solution, while `call` assumes more than one.

Much like you can boot up an Ecto repo and send it queries, you can write queries and send them to SWIPL:

```elixir
defmodule ExProlog.Example do
  use ExProlog.Prolog

  defprolog do
    pairs(x, y) <- [
      member(x, [1, 2, :b]),
      member(y, [9, 8, :a])
    ]
  end
end
```

```elixir
iex(1)> query(pairs(x, y)) |> SWIPL.all()
[
  [x: 1, y: 9],
  [x: 1, y: 8],
  [x: 1, y: :a],
  [x: 2, y: 9],
  [x: 2, y: 8],
  [x: 2, y: :a],
  [x: :b, y: 9],
  [x: :b, y: 8],
  [x: :b, y: :a]
]
iex(1)> xs = [1, 2, 3, 4]
[1, 2, 3, 4]
iex(2)> length(^xs, l) |> query() |> SWIPL.all()
[[l: 4]]
iex(3)> 
```

And that's about it!

At the moment this is really just a janky proof of concept, and many of the integrations are quite brittle. Be careful when calling `SWIPL.all/1` versus `SWIPL.call/1`, for example.

Much of the syntax transformations are done using Elixir's `Macro` and `Code` modules, so it's quite easy to generate invalid Prolog syntax.

Finally, DCGs are very close to actually working, but I need to add some special casing to the codegen.

### To Dos/Ideas

There are a few directions I'd like to experiement with this in.

For example [Nx](https://hexdocs.pm/nx/Nx.Defn.html#defn/2) uses `defn` to allow you to write tensor functions as if they were ordinary mathematical code:

```elixir
defn extract_non_digits(t) do
  t * (not is_digit?(t) and t != ?.)
end

```

I'd like to see what sorts of code a `deflogic` macro, which expands into a function that hits SWIPL behind the scenes could produce. This is a bit contrived, but imagine:

```elixir
defmodule Combos do
  use ExProlog.Prolog

  @xs [1, 2, 3]
  @xs [:a, :b, :c]

  deflogic pairs(x, y) do
    member(x, ^@xs)
    member(y, ^@ys)
  end

  def get_pairs do
    pairs(x, y)
    |> Enum.map(fn [x: x, y: y] -> {x, y} end)
  end

  defdcg seq([]), do: []
  defdcg seq([e|es]) do
    [e]
    seq(es)
  end
end
```

- Pluggable backends, e.g. [Erlog](https://github.com/rvirding/erlog),
- Elegance is not optional etc, none of this looks particularly elegant.
  - Read more Ecto code, as they probably have some good ideas in there
  - Should really be getting everything in [canonical form](https://www.swi-prolog.org/pldoc/man?predicate=write_canonical/1) ASAP.
- Handle errors in any possibly good way
- Make it more Erlangy?
  - The interpreter could really just be a process that takes a query and replies with `{:ok, response} | {:error, error}`.
  - Even better, it could _also_ return `{:cont, response}` indicating it's not done backtracking

#### Syntax

- [ ] `defprolog` block
- [ ] `with` expr for directives
- [x] variable pinning
- [x] single-statement block handling
- [ ] default to CLPZ for arithmetic.
- [ ] cuts
- [ ] prolog namespacing
- [ ] clean up the tests

#### Runtime

- [x] call/all
- [ ] kill port and restart
- [ ] ets table for modules?

- [ ] define function heads to call predicate
- [ ] erlog backend?

### Further reading

- <https://metalevel.at/prolog>
- Nx
- Ecto
