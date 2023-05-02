defmodule TrainingSchedule.MixProject do
  use Mix.Project

  def project do
    [
      app: :training_schedule,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TrainingSchedule.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Password hashing
      {:argon2_elixir, "~> 3.1"},
      # Parsing
      {:nimble_parsec, "~> 1.3"},

      # Webserver / framework
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.7", override: true},
      {:plug_cowboy, "~> 2.5"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.18"},

      # Frontend
      {:heroicons, "~> 0.5"},
      {:esbuild, "~> 0.6", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.10"},

      # Dev / testing tools
      {:tailwind_formatter, "~> 0.3.1", only: :dev, runtime: false},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:sobelow, "~> 0.12", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
