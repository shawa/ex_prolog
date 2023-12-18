defmodule ExProlog.SWIPL do
  use GenServer

  require Logger

  alias ExProlog.Parser

  def start_link(opts) do
    to_consult = Keyword.get(opts, :consult, [])

    GenServer.start_link(__MODULE__, to_consult, name: __MODULE__)
  end

  def init(to_consult \\ []) do
    path = System.find_executable("swipl")
    port = Port.open({:spawn_executable, path}, [:binary, :stderr_to_stdout, args: []])

    Process.link(port)
    Port.monitor(port)

    {:ok, {port, to_consult}}
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

  def consult(module) do
    filepath = write_module(module)
    call("['#{filepath}'].")
  end

  def write_module(module) when is_atom(module) do
    filepath =
      module
      |> Atom.to_string()
      |> filepath_for()

    File.write!(filepath, module.__prolog__())

    filepath
  end

  def filepath_for(file_name) do
    Path.join([
      :code.priv_dir(:ex_prolog),
      "swipl_files",
      "#{file_name}.ex.pl"
    ])
  end

  def do_call(goal, port) do
    Port.command(port, goal <> "\n")

    receive do
      {^port, {:data, message}} -> Parser.parse_terminal_line(message)
    end
  end

  def handle_call({:call, goal}, _from, port) do
    {:reply, do_call(goal, port), port}
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

  def handle_info({port, {:data, "Welcome to SWI-Prolog" <> _rest = message}}, {port, to_consult}) do
    Logger.info(message)
    {:noreply, port, {:continue, {:consult, to_consult}}}
  end

  def handle_continue({:consult, modules}, port) do
    Enum.each(modules, fn module ->
      Logger.info("consulting", module: module)

      filepath = write_module(module)
      do_call("['#{filepath}'].", port)
    end)

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
