import Config

# Use `mix phx.digest` to generate a cached version of
# static files.
config :training_schedule, TrainingScheduleWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
