defmodule ExProlog.Example do
  use ExProlog.Prolog

  defprolog do
    gen(x) <- [
      member(x, [1, 2, 3, 4, 5])
    ]

    pairs(x, y) <- [
      member(x, [1, 2, :b]),
      member(y, [9, 8, :a])
    ]
  end
end
