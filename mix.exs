# TrainingSchedule.ex
# Copyright (c) 2023, Mathijs Saey

# TrainingSchedule.ex is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# TrainingSchedule.ex is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

defmodule TrainingSchedule.MixProject do
  use Mix.Project

  def project do
    [
      app: :training_schedule,
      version: "0.1.0",
      elixir: "~> 1.15",
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
      {:argon2_elixir, "~> 4.0"},
      # Parsing
      {:nimble_parsec, "~> 1.3"},

      # Webserver / framework
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7", override: true},
      {:plug_cowboy, "~> 2.6"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.20"},

      # Frontend
      {:heroicons, "~> 0.5"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.15"},

      # Dev / testing tools
      {:tailwind_formatter, "~> 0.3", only: :dev, runtime: false},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:sobelow, "~> 0.13", only: :dev, runtime: false},
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
