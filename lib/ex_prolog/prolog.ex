defmodule ExProlog.Prolog do
  alias ExProlog.Ast
  alias ExProlog.Codegen

  defmacro __using__(_opts) do
    quote do
      require ExProlog.Prolog
      import ExProlog.Prolog
    end
  end

  defmacro defprolog(_call \\ nil, do: block) do
    quote do
      def __prolog__ do
        compile(
          unquote(Macro.escape(block)),
          binding()
        )
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

  def compile(block, ctx \\ []) do
    prolog_ast =
      Ast.to_prolog(
        block,
        ctx
      )

    Codegen.format(prolog_ast)
  end

  def tag(code, module) do
    """
    % ex_prolog: #{module}

    """ <>
      code
  end
end
