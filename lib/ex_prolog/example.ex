defmodule ExProlog.Example do
  use ExProlog.Prolog

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
  end
end
