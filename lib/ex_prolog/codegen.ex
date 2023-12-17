defmodule ExProlog.Codegen do
  def format_list_innards(list, sep \\ ", ") when is_list(list) do
    list
    |> Enum.map(&format/1)
    |> Enum.join("#{sep}")
  end

  def format({:__block__, terms}) do
    terms
    |> Enum.map(&format/1)
    |> Enum.map(&(&1 <> "."))
    |> Enum.join("\n\n")
    |> then(&(&1 <> "\n"))
  end

  def format({:var, atom}) when is_atom(atom) do
    case Atom.to_string(atom) do
      "_" <> rest ->
        "_" <> String.capitalize(rest)

      otherwise ->
        String.capitalize(otherwise)
    end
  end

  def format(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  def format(integer) when is_integer(integer) do
    Integer.to_string(integer)
  end

  def format(list) when is_list(list) do
    list
    |> format_list_innards()
    |> then(&"[#{&1}]")
  end

  def format({:|, [head, tail]}) do
    "[#{format(head)}|#{format(tail)}]"
  end

  def format(
        {:":-",
         [
           implication,
           goals
         ]}
      )
      when is_list(goals) do
    case implication do
      [] ->
        ":- " <> format_list_innards(goals, ",\n  ")

      term ->
        case goals do
          [goal] -> format(term) <> " :- " <> format(goal)
          goals -> format(term) <> " :-\n  " <> format_list_innards(goals, ",\n  ")
        end
    end
  end

  def format({functor, args}) do
    "#{format(functor)}(#{format_list_innards(args)})"
  end
end
