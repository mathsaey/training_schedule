defmodule TrainingScheduleWeb.ScheduleLive.Index do
  use TrainingScheduleWeb, :live_view

  alias Phoenix.PubSub
  alias TrainingSchedule.PubSub, as: TSPS

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Accounts.User
  alias TrainingScheduleWeb.Endpoint
  alias TrainingScheduleWeb.ScheduleLive.FormComponent

  # TODO: highlight current week / day

  @schedule_weeks 10
  @schedule_days @schedule_weeks * 7 - 1

  @impl true
  def mount(_, _, socket) do
    %User{id: id} = socket.assigns.user
    if connected?(socket), do: Endpoint.subscribe("workouts:#{id}")
    if connected?(socket), do: Endpoint.subscribe("workout_types:#{id}")

    workout_types =
      id
      |> Workouts.list_user_types()
      |> Enum.map(&Workouts.derive_type_template_fields/1)

    {:ok, assign(socket, page_title: "Training Schedule", workout_types: workout_types)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, params(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(:types_changed, socket) do
    {:noreply,
     socket
     |> assign(:workout_types, Workouts.list_user_types(socket.assigns.user.id))
     |> load_workouts()}
  end

  def handle_info(:workouts_changed, socket) do
    {:noreply, load_workouts(socket)}
  end

  @impl true
  def handle_event("workout_moved", %{"workout" => w, "target" => t}, socket) do
    <<"workout_", id::binary>> = w
    <<"cell_", date::binary>> = t
    id |> String.to_integer() |> Workouts.update(%{date: date})
    PubSub.broadcast(TSPS, "workouts:#{socket.assigns.user.id}", :workouts_changed)

    {:noreply, load_workouts(socket)}
  end

  defp params(socket, action, params) do
    Enum.reduce_while(params, %{}, fn
      {"id", id}, acc ->
        {:cont, Map.put(acc, "id", id)}

      {k, date}, acc ->
        case Date.from_iso8601(date) do
          {:ok, date} -> {:cont, Map.put(acc, k, date)}
          {:error, _} -> {:halt, false}
        end
    end)
    |> then(fn
      params when map_size(params) > 0 -> action(socket, action, params)
      _ -> redirect_to_default_url(socket)
    end)
  end

  defp action(socket, :index, %{"from" => from, "to" => to}) do
    maybe_load_between(socket, from, to)
  end

  defp action(socket, action, params) when action in [:new, :edit] do
    socket
    |> maybe_load_between(params["from"], params["to"])
    |> assign(:form_id, params["id"] || :new)
    |> assign(:date, params["date"])
  end

  defp action(socket, _, _), do: redirect_to_default_url(socket)

  defp redirect_to_default_url(socket) do
    from = Date.utc_today() |> Date.beginning_of_week()
    to = Date.add(from, @schedule_days)
    push_patch(socket, to: ~p"/from/#{from}/to/#{to}", replace: true)
  end

  defp maybe_load_between(socket, from, to) do
    case Map.take(socket.assigns, [:from, :to]) do
      %{from: ^from, to: ^to} -> socket
      _ -> load_between(socket, from, to)
    end
  end

  defp load_between(socket, from, to) do
    socket
    |> assign(:to, to)
    |> assign(:from, from)
    |> assign(:back, Date.add(from, -7))
    |> assign(:forward, Date.add(to, 7))
    |> assign(:dates, Date.range(from, to))
    |> assign(:empty_after, noninclusive_date_range(to, Date.end_of_week(to)))
    |> assign(:empty_before, noninclusive_date_range(Date.beginning_of_week(from), from))
    |> load_workouts()
  end

  defp load_workouts(socket) do
    workouts =
      socket.assigns.user.id
      |> Workouts.list_user_workouts(socket.assigns.from, socket.assigns.to)
      |> Enum.map(&Workouts.derive_description/1)
      |> Enum.group_by(& &1.date)

    assign(socket, :workouts, workouts)
  end

  defp noninclusive_date_range(from, to) when from == to, do: []
  defp noninclusive_date_range(from, to), do: Date.range(from, Date.add(to, -1))

  defp cell_border, do: "border border-gray-200 dark:border-gray-600"

  attr :rest, :global
  attr :patch, :string, required: true
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link_button
      class="mx-2 mb-4 rounded-full bg-gray-300 text-gray-500 dark:bg-gray-500 dark:text-gray-100"
      patch={@patch}
      replace
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link_button>
    """
  end
end
