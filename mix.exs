defmodule ExProlog.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_prolog,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExProlog.Application, []}
    ]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
