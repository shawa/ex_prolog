defmodule ExProlog.Codegen do
  @infix_operators [
    :+,
    :-,
    :=,
    :>,
    :<,
    :"=<",
    :>=,
    :"-->",
    :"\\="
  ]

  def format({:__block__, terms}) do
    format_term({:__block__, terms})
  end

  def format(term) do
    format_term(term) <> "."
  end

  def format_term({:__block__, terms}) do
    terms
    |> Enum.map(&format_term/1)
    |> Enum.map(&(&1 <> "."))
    |> Enum.join("\n\n")
    |> then(&(&1 <> "\n"))
  end

  def format_term({:|, [head, tail]}) do
    "[#{format_term(head)}|#{format_term(tail)}]"
  end

  def format_term({operator, [left, right]}) when operator in @infix_operators do
    format_term(left) <> " #{operator} " <> format_term(right)
  end

  def format_term({:":-", [implication, goals]}) when is_list(goals) do
    case implication do
      [] ->
        ":- " <> format_list_innards(goals, ",\n  ")

      term ->
        case goals do
          [goal] -> format_term(term) <> " :- " <> format_term(goal)
          goals -> format_term(term) <> " :-\n  " <> format_list_innards(goals, ",\n  ")
        end
    end
  end

  def format_term({:var, atom}) when is_atom(atom) do
    case Atom.to_string(atom) do
      "_" <> rest ->
        "_" <> String.capitalize(rest)

      otherwise ->
        String.capitalize(otherwise)
    end
  end

  def format_term({functor, args} = ast) do
    "#{format_term(functor)}(#{format_list_innards(args)})"
  end

  def format_term(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  def format_term(integer) when is_integer(integer) do
    Integer.to_string(integer)
  end

  def format_term(list) when is_list(list) do
    list
    |> format_list_innards()
    |> then(&"[#{&1}]")
  end

  defp format_list_innards(list, sep \\ ", ") when is_list(list) do
    list
    |> Enum.map(&format_term/1)
    |> Enum.join("#{sep}")
  end
end
