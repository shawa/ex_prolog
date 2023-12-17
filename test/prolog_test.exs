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

  describe "query/1" do
    test "forms queries" do
      assert Prolog.query(length(l, 4)) == "length(L, 4)."
    end

    test "expands pinned variables (very cool!)" do
      xs = [1, 2, 3]
      assert Prolog.query(length(^xs, 3)) == "length([1, 2, 3], 3)."
    end
  end
end
