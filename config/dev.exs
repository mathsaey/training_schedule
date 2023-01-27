import Config

config :training_schedule, TrainingSchedule.Repo,
  database: Path.expand("../data/dev.db", Path.dirname(__ENV__.file)),
  show_sensitive_data_on_connection_error: true,
  stacktrace: true

config :training_schedule, TrainingScheduleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  url: [host: "localhost"],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "DVN/4rbMDY9oalk6SM6OeXat4nCDNNf7q3HBovc+ggivl0lEpkiIntvlWfkRqCHP",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :training_schedule, TrainingScheduleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/training_schedule_web/(components|controllers|live)/.*(ex|heex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
