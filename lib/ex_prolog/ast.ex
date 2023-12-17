defmodule ExProlog.Ast do
  def parse(elixir_ast) do
    elixir_ast
    |> ensure_block()
    |> to_prolog()
  end

  def ensure_block({:__block__, _args} = block), do: block
  def ensure_block(arg), do: {:__block__, [arg]}

  def to_prolog({:<-, meta, args}) when is_list(args) do
    to_prolog({:":-", meta, args})
  end

  def to_prolog({:~>, meta, args}) when is_list(args) do
    to_prolog({:"-->", meta, args})
  end

  def to_prolog({:<-, [], [{:{}, [], []}, rhs_args]}) do
    to_prolog({:":-", [], [[], to_prolog(rhs_args)]})
  end

  def to_prolog([{:|, meta, [head, tail]}]) do
    to_prolog({:|, meta, [head, tail]})
  end

  def to_prolog({functor, _meta, args}) when is_list(args) do
    {functor, to_prolog(args)}
  end

  def to_prolog({variable_name, _meta, module}) when is_atom(module) do
    {:var, variable_name}
  end

  def to_prolog(atom) when is_atom(atom), do: atom
  def to_prolog(number) when is_number(number), do: number

  def to_prolog(terms) when is_list(terms) do
    Enum.map(terms, &to_prolog/1)
  end
end
