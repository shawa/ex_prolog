defmodule ExProlog.Example do
  use ExProlog.Prolog

  prolog do
    gen(x) <- [
      member(x, [1, 2, 3, 4, 5])
    ]
  end
end
