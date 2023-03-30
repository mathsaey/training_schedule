defmodule TrainingScheduleWeb.ScheduleLive.FormComponent do
  use TrainingScheduleWeb, :live_component
  alias TrainingSchedule.Workouts
  alias Ecto.Changeset

  @impl true
  def update(assigns, socket) do
    workout = workout(assigns.id, assigns)
    types = Workouts.user_types(assigns.user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:type, workout.type)
     |> assign(:types, types)
     |> assign(:preview, workout)
     |> assign(:workout, workout)
     |> assign(:changeset, Workouts.changeset(workout))
     |> assign(:dummy_type, Workouts.dummy_type(assigns.user))}
  end

  defp workout(:new, assigns), do: Workouts.dummy(assigns.user)
  defp workout(id, _), do: id |> String.to_integer() |> Workouts.get()

  @impl true
  def handle_event("change", %{"workout" => params}, socket) do
    changeset =
      socket.assigns.workout
      |> Workouts.changeset(params)
      |> Map.replace!(:action, :validate)

    # Avoid repetitive querying to generate the preview, search in the preloaded list of types
    type_id = Changeset.fetch_field!(changeset, :type_id)
    type = Enum.find(socket.assigns.types, socket.assigns.dummy_type, &(&1.id == type_id))
    preview = %{Changeset.apply_changes(changeset) | type: type}

    {:noreply,
     socket
     |> assign(:type, type)
     |> assign(:preview, preview)
     |> assign(:changeset, changeset)}
  end

  def handle_event("save", %{"workout" => params}, socket) do
    workout = Map.put(socket.assigns.workout, :type, nil)

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
    {:noreply, push_patch(socket, to: ~p"/from/#{socket.assigns.from}/to/#{socket.assigns.to}", replace: true)}
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
