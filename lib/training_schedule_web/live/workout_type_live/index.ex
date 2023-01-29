defmodule TrainingScheduleWeb.WorkoutTypeLive.Index do
  use TrainingScheduleWeb, :live_view

  alias TrainingScheduleWeb.Endpoint
  alias TrainingScheduleWeb.WorkoutTypeLive.FormComponent

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    %User{id: id} = socket.assigns.user
    if connected?(socket), do: Endpoint.subscribe("workout_types:#{id}")
    {:ok, assign(socket, :workout_types, Workouts.list_user_types(id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(:types_changed, socket) do
    {:noreply, assign(socket, :workout_types, Workouts.list_user_types(socket.assigns.user.id))}
  end

  defp action(socket, :index, _), do: assign(socket, :page_title, "Workout Types")

  defp action(socket, :new, _) do
    socket
    |> assign(:page_title, "Workouts: New Type")
    |> assign(:form_id, :new)
  end

  defp action(socket, :edit, %{"name" => name}) do
    socket
    |> assign(:page_title, "Workouts: #{name}")
    |> assign(:form_id, name)
    |> assign(:type, Workouts.get_type_by_name(socket.assigns.user.id, name))
  end
end
