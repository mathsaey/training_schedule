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

defmodule TrainingScheduleWeb.ScheduleLive.FormComponent do
  use TrainingScheduleWeb, :live_component
  alias TrainingSchedule.Workouts

  @impl true
  def update(assigns, socket) do
    workout = workout(assigns.id, assigns)
    type_options = assigns.user |> Workouts.user_types() |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:preview, workout)
     |> assign(:workout, workout)
     |> assign(:type_options, type_options)
     |> assign(:changeset, Workouts.changeset(workout))
     |> assign(Map.take(assigns, [:from, :to, :date, :action, :user]))}
  end

  defp workout(:new, assigns), do: Workouts.dummy(assigns.user)
  defp workout(id, _), do: id |> String.to_integer() |> Workouts.get()

  @impl true
  def handle_event("change", %{"workout" => params}, socket) do
    changeset =
      socket.assigns.workout
      |> Workouts.changeset(params)
      |> Map.replace!(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:preview, Workouts.apply_changes(changeset))}
  end

  def handle_event("save", %{"workout" => params}, socket) do
    workout = %{socket.assigns.workout | type: nil}

    case socket.assigns.action do
      :new -> Workouts.create(workout, params)
      :edit -> Workouts.update(workout, params)
    end
    |> case do
      {:ok, _} -> after_update(socket)
      {:error, cs} -> {:noreply, assign(socket, :changeset, cs)}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Workouts.delete(socket.assigns.workout)
    after_update(socket)
  end

  def after_update(socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/from/#{socket.assigns.from}/to/#{socket.assigns.to}",
       replace: true
     )}
  end

  attr :form, :any, required: true
  attr :type, :any, required: true

  def description_field_inputs(assigns) do
    ~H"""
    <div>
      <.input
        :for={name <- @type.template_fields}
        field={{@form, :description_fields}}
        id={"#{Phoenix.HTML.Form.input_id(@form, :description_fields)}_#{name}"}
        name={"#{Phoenix.HTML.Form.input_name(@form, :description_fields)}[#{name}]"}
        label={name}
        value={Phoenix.HTML.Form.input_value(@form, :description_fields)[name] || ""}
      />
    </div>
    """
  end
end
