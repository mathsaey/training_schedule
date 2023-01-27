import Config

config :training_schedule, TrainingSchedule.Repo,
  database: Path.expand("../data/test.db", Path.dirname(__ENV__.file)),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :training_schedule, TrainingScheduleWeb.Endpoint, server: false

# Use less expensive password hashing for tests
config :argon2_elixir, t_cost: 1, m_cost: 8

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
