defmodule ExProlog.AstTest do
  use ExUnit.Case

  import ExProlog.Ast

  describe "to_prolog/1" do
    # variables
    test "variables" do
      term =
        quote do
          a
        end

      assert to_prolog(term) == {:var, :a}
    end

    test "underscore" do
      term =
        quote do
          _
        end

      assert to_prolog(term) == {:var, :_}
    end

    # atomic terms
    test "atoms" do
      term =
        quote do
          :an_atom
        end

      assert to_prolog(term) == :an_atom
    end

    test "numbers" do
      term =
        quote do
          1
        end

      assert to_prolog(term) == 1
    end

    # lists
    test "lists" do
      term =
        quote do
          [1, 2, a, :atom]
        end

      assert to_prolog(term) == [1, 2, {:var, :a}, :atom]
    end

    test "simple cons list" do
      term =
        quote do
          [:x | t]
        end

      assert to_prolog(term) == {:|, [:x, {:var, :t}]}
    end

    # test "compound cons list" do
    #   term =
    #     quote do
    #       [:x | t, b, c]
    #     end

    #   assert to_prolog(term) == {:|, [:x, [{:var, :t}, {:var, :b}, {:var, :c}]]}
    # end

    # compound terms
    test "compound terms" do
      term =
        quote do
          functor_name(:atom, arg, [1, 2])
        end

      assert to_prolog(term) == {:functor_name, [:atom, {:var, :arg}, [1, 2]]}
    end

    # facts
    test "facts" do
      term =
        quote do
          fact(:atom, :other_atom)
        end

      assert to_prolog(term) == {:fact, [:atom, :other_atom]}
    end

    # rules
    test "simple rule" do
      term =
        quote do
          :atom <- [other_term]
        end

      assert to_prolog(term) == {:":-", [:atom, [{:var, :other_term}]]}
    end

    test "compound rule" do
      term =
        quote do
          dependent(x, y) <- [pred(x), pred(y), pred(z)]
        end

      assert to_prolog(term) ==
               {:":-",
                [
                  {:dependent, [var: :x, var: :y]},
                  [pred: [var: :x], pred: [var: :y], pred: [var: :z]]
                ]}
    end

    test "dcg" do
      term =
        quote do
          dcg(x) ~> [{y = x}, x]
        end

      # note the double-length arrow (-> versus -->)
      assert to_prolog(term) ==
               {
                 :"-->",
                 [
                   {:dcg, [var: :x]},
                   [{}: [=: [var: :y, var: :x]], var: :x]
                 ]
               }
    end

    test "directive (unary :-)" do
      terms =
        quote do
          [] <- [:goal, :other_goal]
        end

      assert to_prolog(terms) ==
               {:":-", [[], [:goal, :other_goal]]}
    end

    test "multiple terms" do
      terms =
        quote do
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

      assert to_prolog(terms) ==
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
                  "-->": [
                    {:optional, [var: :x]},
                    [[var: :x], [optional: [var: :x]]]
                  ]
                ]}
    end

    test "pinned variable expansion" do
      term =
        quote do
          [y, ^x]
        end

      context = [x: 1]

      assert to_prolog(term, context) == [{:var, :y}, 1]
    end
  end
end
