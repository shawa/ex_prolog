defmodule ExProlog.Parser do
  def parse_terminal_line(line) do
    case String.reverse(line) do
      "\n\n." <> rest ->
        rest
        |> String.reverse()
        |> parse()

      other ->
        other
    end
  end

  def parse_compound_line(line) do
    line
    |> then(&"[#{&1}]")
    |> parse()
    |> Enum.map(&extract_assign/1)
  end

  def extract_assign(false), do: false

  def extract_assign({:=, _, [{var, [], nil}, value]}) do
    {var, parse_elixir_ast(value)}
  end

  def parse(str) do
    str
    |> Code.string_to_quoted!()
    |> parse_elixir_ast()
  end

  def parse_elixir_ast({:=, _, [{:__aliases__, _, [var]}, value]}) do
    new_var = var |> Atom.to_string() |> String.downcase() |> String.to_atom()

    {:=, [], [{new_var, [], nil}, parse_elixir_ast(value)]}
  end

  def parse_elixir_ast({atom, _, nil}) when is_atom(atom) do
    atom
  end

  def parse_elixir_ast({functor, _, args}) do
    {functor, [], parse_elixir_ast(args)}
  end

  def parse_elixir_ast(list) when is_list(list) do
    Enum.map(list, &parse_elixir_ast/1)
  end

  def parse_elixir_ast(n) when is_integer(n), do: n
  def parse_elixir_ast(atom) when is_atom(atom), do: atom

  def parse_elixir_ast(nil), do: nil
end
