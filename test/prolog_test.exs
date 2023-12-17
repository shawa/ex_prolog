defmodule ExProlog.PrologTest do
  alias ExProlog.Prolog
  require ExProlog.Prolog

  use ExUnit.Case

  describe "compile/1" do
    test "single goal edge case" do
      block =
        quote do
          gen(x) <- [
            member(x, [1, 2, 3, 4, 5])
          ]
        end

      assert Prolog.compile(block) == "gen(X) :- member(X, [1, 2, 3, 4, 5])."
    end
  end
end
