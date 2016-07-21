defmodule Inxect.Mixfile do
  use Mix.Project

  def project do
    [app: :inxect,
     version: "0.1.2",
     description: "Package to make dependency injection easier, see documentation for more infos",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: Mix.env != :test,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp package do
    [# These are the default files included in the package
     name: :inxect,
     files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Daniel Romero, @danielromerobaseclass"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/baseclass/inxect" }]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
