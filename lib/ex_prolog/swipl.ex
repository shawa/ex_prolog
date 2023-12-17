defmodule ExProlog.SWIPL do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec init(any()) :: {:ok, port()}
  def init(opts) do
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

    consult(filepath)
  end

  def consult(filepath) do
    # ++ rules ++ ["\n\04"]
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
        {^port, message} -> message
      end

    {:reply, reply, port}
  end

  def unroll_solutions do
    receive do
      {_port, value} ->
        nil
        # code
    end
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

  def halt do
    cast("halt.")
  end

  def format_goals(goals) do
    goals
    |> Enum.join("\n")
  end
end
