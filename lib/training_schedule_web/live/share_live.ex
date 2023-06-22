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

defmodule TrainingScheduleWeb.ShareLive do
  use TrainingScheduleWeb, :live_view

  alias TrainingSchedule.Shares
  alias TrainingSchedule.Shares.Share
  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Cycles

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Shares.get(id) do
      nil ->
        socket
        |> put_flash(:error, "That share does not exist")
        |> assign(share: nil, cycles: [])
        |> then(&{:ok, &1})

      share = %Share{user_id: user_id} ->
        if connected?(socket), do: Endpoint.subscribe("workouts:#{user_id}")
        {:ok, socket |> assign(share: share) |> load_workouts(share)}
    end
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket |> load_workouts(socket.assigns.share)}

  defp load_workouts(socket, %Share{user_id: user_id, from: from, to: to}) do
    Workouts.user_workouts(user_id, from, to)
    |> Cycles.group_workouts(Date.beginning_of_week(from), Date.end_of_week(to), 7)
    |> then(&assign(socket, :cycles, &1))
  end
end
