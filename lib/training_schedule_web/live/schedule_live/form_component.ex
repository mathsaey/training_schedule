defmodule TrainingScheduleWeb.ScheduleLive.FormComponent do
  use TrainingScheduleWeb, :live_component
  alias TrainingSchedule.Workouts

  alias TrainingSchedule.PubSub, as: TSPS
  alias Phoenix.PubSub
  alias Ecto.Changeset

  @impl true
  def update(assigns, socket) do
    workout = workout(assigns.id, assigns)
    changeset = Workouts.changeset(workout)
    workout_types = Enum.map(assigns.types, &{&1.name, &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:type, workout.type)
     |> assign(:preview, workout)
     |> assign(:workout, workout)
     |> assign(:changeset, changeset)
     |> assign(:workout_types, workout_types)}
  end

  @impl true
  def handle_event("change", %{"workout" => params}, socket) do
    changeset =
      socket.assigns.workout
      |> Workouts.changeset(params)
      |> Map.replace!(:action, :validate)

    type_id = Changeset.fetch_field!(changeset, :type_id)
    type = Enum.find(socket.assigns.types, dummy_type(), &(&1.id == type_id))
    preview = %{Changeset.apply_changes(changeset) | type: type} |> Workouts.derive_description()

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
    PubSub.broadcast(TSPS, "workouts:#{socket.assigns.user.id}", :workouts_changed)
    {:noreply, push_patch(socket, to: ~p"/from/#{socket.assigns.from}/to/#{socket.assigns.to}", replace: true)}
  end

  def workout(:new, assigns) do
    %{
      Ecto.build_assoc(assigns.user, :workouts)
      | distance: 0,
        type: dummy_type(),
        description_fields: %{}
    }
  end

  def workout(id, assigns) when is_binary(id) do
    workout = id |> String.to_integer() |> Workouts.get()
    type = Enum.find(assigns.types, dummy_type(), &(&1.id == workout.type_id))
    %{workout | type: type} |> Workouts.derive_description()
  end

  defp dummy_type do
    %Workouts.Type{name: "Workout", color: "#0e7490", template: "", template_fields: []}
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
