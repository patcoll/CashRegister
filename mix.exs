defmodule CashRegister.MixProject do
  use Mix.Project

  def project do
    [
      app: :cash_register,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: ["test.watch": :test, format: :test, dialyzer: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
