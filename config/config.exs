import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :training_schedule, ecto_repos: [TrainingSchedule.Repo]
config :training_schedule, TrainingSchedule.Repo, pool_size: 5

config :training_schedule, TrainingScheduleWeb.Endpoint,
  live_view: [signing_salt: "RUqrhYyGIkTiSKvBOZ11/UMxEwEVaErx"],
  pubsub_server: TrainingSchedule.PubSub,
  render_errors: [
    formats: [html: TrainingScheduleWeb.ErrorHTML, json: TrainingScheduleWeb.ErrorJSON],
    layout: false
  ]

config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.18.6",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"
