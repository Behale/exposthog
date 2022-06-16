defmodule Posthog.MixProject do
  use Mix.Project

  def project do
    [
      app: :exposthog,
      version: "0.1.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    []
  end

  defp description do
    """
    Elixir HTTP client for Posthog.
    """
  end

  defp package do
    [
      name: :posthog,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Nick Kezhaya", "Rafael Ballestiero"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Behale/exposthog"}
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.10"},
      {:jason, "~> 1.2", optional: true},
      {:ex_doc, ">= 0.0.0", only: [:doc]}
    ]
  end
end
