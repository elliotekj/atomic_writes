defmodule AtomicWrites.MixProject do
  use Mix.Project

  @version "1.0.0"
  @repo_url "https://github.com/elliotekj/atomic_writes"

  def project do
    [
      app: :atomic_writes,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:styler, "~> 0.9", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Elliot Jackson"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp description do
    """
    Serialized, atomic file writes in Elixir.
    """
  end

  defp docs do
    [
      name: "AtomicWrites",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/atomic_writes",
      source_url: @repo_url,
      extras: ["README.md"]
    ]
  end
end
