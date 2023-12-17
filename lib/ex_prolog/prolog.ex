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
        unquote(compile(block))
      end
    end
  end

  defmacro prolog(_call \\ nil, do: block) do
    quote do
      unquote(compile(block))
    end
  end

  def compile(block) do
    block
    |> Ast.to_prolog()
    |> Codegen.format()

    # |> tag(__MODULE__)
  end

  def tag(code, module) do
    """
    % ex_prolog: #{module}

    """ <>
      code
  end
end
