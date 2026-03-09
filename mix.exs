defmodule BggApiClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :bgg_api_client,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BggApiClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.12"},
      {:mint, "~> 1.6"},
      {:castore, "~> 1.0"},
      {:sweet_xml, "~> 0.7"}
    ]
  end
end
