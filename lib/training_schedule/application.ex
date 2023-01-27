defmodule TrainingSchedule.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrainingSchedule.Repo,
      {Phoenix.PubSub, name: TrainingSchedule.PubSub},
      TrainingScheduleWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TrainingSchedule.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TrainingScheduleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
