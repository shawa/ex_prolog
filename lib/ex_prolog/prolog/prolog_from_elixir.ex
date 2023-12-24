defmodule ExProlog.Prolog.PrologFromElixir do
  def to_prolog(term, bindings \\ [])

  def to_prolog({:^, _, [{variable, _meta, _module}]}, bindings) do
    binding = Keyword.fetch!(bindings, variable)
    to_prolog(binding)
  end

  @operator_mappings [
    {:~>, :"-->"},
    {:<-, :":-"},
    {:!=, :"\\="},
    {:<=, :"=<"}
  ]

  for {elixir_op, prolog_op} <- @operator_mappings do
    def to_prolog({unquote(elixir_op), meta, args}, bindings) do
      to_prolog({unquote(prolog_op), meta, args}, bindings)
    end
  end

  def to_prolog({:":-", [], [{:{}, [], []}, rhs_args]}, bindings) do
    to_prolog({:":-", [], [[], to_prolog(rhs_args)]}, bindings)
  end

  def to_prolog([{:|, meta, [head, tail]}], bindings) do
    to_prolog({:|, meta, [head, tail]}, bindings)
  end

  def to_prolog({functor, _meta, args}, bindings) when is_list(args) do
    {functor, to_prolog(args, bindings)}
  end

  def to_prolog({variable_name, _meta, module}, _bindings) when is_atom(module) do
    {:var, variable_name}
  end

  def to_prolog(atom, _bindings) when is_atom(atom), do: atom
  def to_prolog(number, _) when is_number(number), do: number

  def to_prolog(terms, bindings) when is_list(terms) do
    Enum.map(terms, &to_prolog(&1, bindings))
  end
end
