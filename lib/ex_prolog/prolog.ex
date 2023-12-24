defmodule ExProlog.Prolog do
  alias ExProlog.Prolog.PrologFromElixir

  defmacro __using__(_opts) do
    quote do
      require ExProlog.Prolog
      import ExProlog.Prolog
    end
  end

  defmacro defprolog(_call \\ nil, do: block) do
    quote do
      def __prolog__ do
        unquote(Macro.escape(block))
        |> compile(binding())
        |> tag(__MODULE__)
      end
    end
  end

  defmacro query(call) do
    quote do
      ExProlog.Prolog.compile(
        unquote(Macro.escape(call)),
        binding()
      )
    end
  end

  def predicates(block) do
    Macro.traverse(
      block,
      [],
      fn node, acc ->
        {node, [node | acc]}
      end,
      fn node, acc -> {node, acc} end
    )
  end

  def compile(block, ctx \\ []) do
    block
    |> PrologFromElixir.to_prolog(ctx)
    |> ExProlog.Prolog.CodeGeneration.format()
  end

  def tag(code, module) do
    """
    % ex_prolog: #{module}

    """ <>
      code
  end
end
