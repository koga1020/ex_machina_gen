defmodule ExMachinaGen.MixProject do
  use Mix.Project

  @project_url "https://github.com/koga1020/ex_machina_gen"

  def project do
    [
      app: :ex_machina_gen,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExMachinaGen",
      description: "additional mix task for ExMachina.",
      package: package(),
      source_url: @project_url,
      homepage_url: @project_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5.4", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.5.1", only: [:dev, :test], runtime: false},
      {:inflex, "~> 2.1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["koga1020"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url
      }
    ]
  end
end
