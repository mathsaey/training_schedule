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

defmodule TrainingScheduleWeb.WorkoutTypeLive.Index do
  use TrainingScheduleWeb, :live_view

  alias TrainingScheduleWeb.Endpoint
  alias TrainingScheduleWeb.WorkoutTypeLive.FormComponent

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    %User{id: id} = socket.assigns.user
    if connected?(socket), do: Endpoint.subscribe("workouts:#{id}")
    {:ok, assign(socket, :types, Workouts.user_types(id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:types, _, _}, socket) do
    {:noreply, assign(socket, :types, Workouts.user_types(socket.assigns.user.id))}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp action(socket, :index, _) do
    socket
    |> assign(:page_title, "Workout Types")
  end

  defp action(socket, :new, _) do
    socket
    |> assign(:page_title, "Workouts: New Type")
    |> assign(:form_id, :new)
  end

  defp action(socket, :edit, %{"name" => name}) do
    socket
    |> assign(:page_title, "Workouts: #{name}")
    |> assign(:form_id, name)
    |> assign(:type, Workouts.type_by_name(socket.assigns.user.id, name))
  end
end
