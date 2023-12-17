defmodule ExProlog.SWIPL do
  use GenServer

  require Logger

  alias ExProlog.Parser

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts \\ []) do
    path = System.find_executable("swipl")
    port = Port.open({:spawn_executable, path}, [:binary, :stderr_to_stdout, args: []])

    Process.link(port)
    Port.monitor(port)

    {:ok, port}
  end

  @spec call(String.t()) :: any()
  def call(goal) do
    GenServer.call(__MODULE__, {:call, goal})
  end

  @spec all(String.t()) :: any()
  def all(goal) do
    GenServer.call(__MODULE__, {:all, goal})
  end

  @spec cast(String.t()) :: any()
  def cast(goal) do
    GenServer.cast(__MODULE__, {:cast, goal})
  end

  def consult(module) when is_atom(module) do
    filepath =
      module
      |> Atom.to_string()
      |> filepath_for()

    File.write!(filepath, module.__prolog__())

    call("consult('#{filepath}').")
  end

  def filepath_for(file_name) do
    Path.join([
      :code.priv_dir(:ex_prolog),
      "swipl_files",
      "#{file_name}.ex.pl"
    ])
  end

  def handle_call({:call, goal}, _from, port) do
    Port.command(port, goal <> "\n")

    reply =
      receive do
        {^port, {:data, message}} -> Parser.parse_terminal_line(message)
      end

    {:reply, reply, port}
  end

  def handle_call({:all, goal}, _, port) do
    reply =
      goal
      |> unroll([], port)
      |> Enum.map(&Parser.parse_compound_line/1)

    {:reply, reply, port}
  end

  def handle_cast({:cast, goal}, port) do
    Port.command(port, goal <> "\n")

    {:noreply, port}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, port) do
    {:stop, :normal, port}
  end

  def handle_info({port, {:data, "Welcome to SWI-Prolog" <> _rest = message}}, port) do
    Logger.info(message)
    {:noreply, port}
  end

  defp unroll(goal, acc, port) do
    Port.command(port, goal <> "\n")

    reply =
      receive do
        {^port, {:data, message}} -> message
      end

    case String.reverse(reply) do
      "\n\n." <> rest ->
        [String.reverse(rest) | acc]
        |> Enum.map(&String.trim/1)
        |> Enum.reverse()

      _ ->
        unroll(";", [reply | acc], port)
    end
  end
end
