defmodule ExProlog.Prolog.PrologFromElixirTest do
  use ExUnit.Case

  import ExProlog.Prolog.PrologFromElixir

  defmacro assert_parses_as(expected, context \\ [], do: block) do
    quote do
      assert to_prolog(
               unquote(Macro.escape(block)),
               unquote(context)
             ) == unquote(expected)
    end
  end

  describe "to_prolog/1" do
    test "variables" do
      assert_parses_as({:var, :a}) do
        a
      end

      assert_parses_as({:var, :_}) do
        _
      end

      assert_parses_as({:var, :_ignore}) do
        _ignore
      end
    end

    test "scalar literals" do
      assert_parses_as(:an_atom) do
        :an_atom
      end

      assert_parses_as(1) do
        1
      end
    end

    test "lists" do
      assert_parses_as([1, 2, {:var, :a}, :atom]) do
        [1, 2, a, :atom]
      end

      assert_parses_as({:|, [:x, {:var, :t}]}) do
        [:x | t]
      end
    end

    test "facts" do
      assert_parses_as({:functor, [:atom, {:var, :arg}, [1, 2]]}) do
        functor(:atom, arg, [1, 2])
      end
    end

    test "rules" do
      assert_parses_as(
        {:":-",
         [
           {:functor, [var: :x, var: :y]},
           [p: [var: :x], q: [var: :y]]
         ]}
      ) do
        functor(x, y) <- [
          p(x),
          q(y)
        ]
      end
    end

    test "dcg" do
      assert_parses_as(
        # note the double-length arrow (-> versus -->)
        {:"-->",
         [
           {:dcg, [var: :x]},
           [{}: [=: [var: :y, var: :x]], var: :x]
         ]}
      ) do
        dcg(x) ~> [{y = x}, x]
      end
    end

    test "directive (unary :-)" do
      assert_parses_as({:":-", [[], [:goal, :other_goal]]}) do
        [] <- [:goal, :other_goal]
      end
    end

    test "relations" do
      assert_parses_as({:=, [1, 2]}) do
        1 = 2
      end

      assert_parses_as({:"\\=", [1, 2]}) do
        1 != 2
      end

      assert_parses_as({:>=, [1, 2]}) do
        1 >= 2
      end

      assert_parses_as({:"=<", [1, 2]}) do
        1 <= 2
      end

      assert_parses_as({:>, [1, 2]}) do
        1 > 2
      end

      assert_parses_as({:<, [1, 2]}) do
        1 < 2
      end
    end

    test "multiple terms" do
      assert_parses_as(
        {:__block__,
         [
           ":-": [[], [use_module: [library: [:clpfd]]]],
           parent: [:john, :joe],
           parent: [:john, :mary],
           ":-": [
             {:sibling, [var: :x, var: :y]},
             [parent: [var: :p, var: :y], parent: [var: :p, var: :x]]
           ],
           "-->": [{:optional, [var: :_]}, []],
           "-->": [{:optional, [var: :x]}, [[var: :x], [optional: [var: :x]]]]
         ]}
      ) do
        [] <- [use_module(library(:clpfd))]

        parent(:john, :joe)
        parent(:john, :mary)

        sibling(x, y) <-
          [
            parent(p, y),
            parent(p, x)
          ]

        optional(_) ~> []
        optional(x) ~> [[x], [optional(x)]]
      end
    end

    test "pinned variable expansion" do
      assert_parses_as([{:var, :y}, 1], x: 1) do
        [y, ^x]
      end
    end
  end
end
