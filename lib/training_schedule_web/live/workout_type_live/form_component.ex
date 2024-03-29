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

defmodule TrainingScheduleWeb.WorkoutTypeLive.FormComponent do
  use TrainingScheduleWeb, :live_component

  alias Ecto.Changeset
  alias TrainingSchedule.Workouts

  @impl true
  def update(assigns, socket) do
    type = type(assigns.id, assigns.user)
    changeset = Workouts.type_changeset(type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:type, type)
     |> assign(:preview, type)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Workouts.delete_type(socket.assigns.type)
    after_update(socket)
  end

  def handle_event("change", %{"type" => params}, socket) do
    changeset =
      socket.assigns.type
      |> Workouts.type_changeset(params)
      |> Map.replace!(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:preview, Changeset.apply_changes(changeset))}
  end

  def handle_event("save", %{"type" => params}, socket) do
    case socket.assigns.action do
      :new -> Workouts.create_type(socket.assigns.type, params)
      :edit -> Workouts.update_type(socket.assigns.type, params)
    end
    |> case do
      {:ok, _} -> after_update(socket)
      {:error, cs} -> {:noreply, assign(socket, :changeset, cs)}
    end
  end

  defp after_update(socket) do
    socket
    |> push_patch(to: ~p"/types", replace: true)
    |> then(&{:noreply, &1})
  end

  defp type(:new, user), do: Workouts.dummy_type(user, template: "{reps}x{distance}@{speed}")
  defp type(name, user), do: Workouts.type_by_name(user.id, name)
end
