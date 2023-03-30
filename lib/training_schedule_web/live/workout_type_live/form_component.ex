defmodule TrainingScheduleWeb.WorkoutTypeLive.FormComponent do
  use TrainingScheduleWeb, :live_component
  alias TrainingSchedule.Workouts

  alias TrainingSchedule.PubSub, as: TSPS
  alias Phoenix.PubSub
  alias Ecto.Changeset

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
    PubSub.broadcast(TSPS, "workout_types:#{socket.assigns.user.id}", :types_changed)

    socket
    |> push_patch(to: ~p"/workouts", replace: true)
    |> then(&{:noreply, &1})
  end

  defp type(:new, user) do
    %{
      Ecto.build_assoc(user, :workout_types)
      | name: "Workout",
        color: "#D97706",
        template: "{reps}x{distance}@{speed}"
    }
  end

  defp type(name, user), do: Workouts.get_type_by_name(user.id, name)

  defp inline_code(assigns) do
    ~H"""
    <code class="px-1 bg-zinc-400 font-mono border"><%= render_slot(@inner_block) %></code>
    """
  end
end
