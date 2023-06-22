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

defmodule TrainingSchedule.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrainingSchedule.Repo,
      TrainingSchedule.Workouts.TypeCache,
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
