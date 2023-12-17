defmodule ExProlog.CodegenTest do
  use ExUnit.Case

  import ExProlog.Codegen

  describe "format/1" do
    test "variables" do
      assert format({:var, :a}) == "A"
    end

    test "underscore" do
      assert format({:var, :_}) == "_"
    end

    test "underscore variables" do
      assert format({:var, :_ignore}) == "_Ignore"
    end

    test "atoms" do
      assert format(:a) == "a"
    end

    test "numbers" do
      assert format(1) == "1"
    end

    test "lists" do
      assert format([1, 2, {:var, :a}, :atom]) == "[1, 2, A, atom]"
    end

    test "cons list" do
      assert format({:|, [:x, {:var, :t}]}) == "[x|T]"
    end

    test "compound term" do
      assert format({:functor_name, [:atom, {:var, :arg}, [1, 2]]}) ==
               "functor_name(atom, Arg, [1, 2])"
    end

    test "simple rule" do
      assert format({:":-", [:atom, [{:var, :other_term}]]}) == "atom :- Other_term"
    end

    test "compound rule" do
      assert format(
               {:":-",
                [
                  {:dependent, [var: :x, var: :y]},
                  [pred: [var: :x], pred: [var: :y], pred: [var: :z]]
                ]}
             ) == "dependent(X, Y) :-\n  pred(X),\n  pred(Y),\n  pred(Z)"
    end

    test "block" do
      assert format(
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
             ) ==
               """
               :- use_module(library(clpfd)).

               parent(john, joe).

               parent(john, mary).

               sibling(X, Y) :-
                 parent(P, Y),
                 parent(P, X).

               -->(optional(_), []).

               -->(optional(X), [[X], [optional(X)]]).
               """
    end
  end
end
