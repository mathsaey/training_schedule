defmodule TrainingSchedule.Repo do
  use Ecto.Repo,
    otp_app: :training_schedule,
    adapter: Ecto.Adapters.SQLite3
end
