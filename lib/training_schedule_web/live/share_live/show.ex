# TrainingSchedule.ex
# Copyright (c) 2023-2026, Mathijs Saey

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

defmodule TrainingScheduleWeb.ShareLive.Show do
  use TrainingScheduleWeb, :live_view

  alias TrainingSchedule.Shares
  alias TrainingSchedule.Shares.Share
  alias TrainingSchedule.Cycles

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Shares.get(id) do
      nil ->
        socket
        |> put_flash(:error, "That share does not exist")
        |> assign(share: nil, cycles: [])
        |> then(&{:ok, &1})

      share = %Share{user_id: user_id, name: name} ->
        if connected?(socket) do
          Endpoint.subscribe("workouts:#{user_id}")
          Endpoint.subscribe("shares:#{id}")
        end

        {:ok, socket |> assign(share: share, name: name) |> load_workouts(share)}
    end
  end

  @impl true
  def handle_info({:workouts, _, _}, socket) do
    {:noreply, socket |> load_workouts(socket.assigns.share)}
  end

  def handle_info({:shares, :update, share}, socket) do
    {:noreply, socket |> assign(share: share) |> load_workouts(share)}
  end

  def handle_info({:shares, :delete, _}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "This share has been deleted")
     |> redirect(to: ~p"/")}
  end

  # Temporary workaround. Should be handled through the url of the share later
  # Generalize schedule live view into a (live) component first
  defp load_workouts(socket, share = %Share{from: nil, to: nil}) do
    now = Date.utc_today()
    from = Date.shift(now, Duration.new!(week: -1))
    to = Date.shift(now, Duration.new!(week: 10))

    load_workouts(socket, %{share | from: from, to: to})
  end

  defp load_workouts(socket, share) do
    share
    |> Shares.workouts(nil, nil)
    |> Cycles.group_workouts(Date.beginning_of_week(share.from), Date.end_of_week(share.to), 7)
    |> then(&assign(socket, :cycles, &1))
  end
end
