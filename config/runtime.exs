import Config

# Only activates phoenix when the PHX_SERVER env variable is set. This is automatically done by
# the bin/server script generated as part of a release.
if System.get_env("PHX_SERVER") do
  config :training_schedule, TrainingScheduleWeb.Endpoint, server: true
end

# Fetch the following values from environment variables. This is only done for production builds.
# Defaults for other builds are set in `config/dev.exs` and `config/test.exs`.
if config_env() == :prod do
  database_path =
    System.get_env("TS_DB_PATH") ||
      raise """
      environment variable TS_DB_PATH is missing.
      For example: /var/lib/training_schedule/training_schedule.db
      """

  secret_key_base =
    System.get_env("TS_SECRET_BASE_KEY") ||
      raise """
      environment variable TS_SECRET_BASE_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("TS_HOST") ||
      raise """
      environment variable TS_HOST is missing.
      For example: training.example.com
      """

  ip = :inet.parse_address(String.to_charlist(System.get_env("TS_IP") || "0.0.0.0"))
  port = String.to_integer(System.get_env("TS_PORT") || "4000")

  config :training_schedule, TrainingSchedule.Repo, database: database_path

  config :training_schedule, TrainingScheduleWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: ip, port: port],
    secret_key_base: secret_key_base
end
