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

defmodule TrainingScheduleWeb.ScheduleLive.Index do
  use TrainingScheduleWeb, :live_view

  alias TrainingSchedule.Cycles
  alias TrainingSchedule.Workouts
  alias TrainingScheduleWeb.ScheduleLive.FormComponent

  @schedule_weeks 10
  @schedule_days @schedule_weeks * 7 - 1

  @impl true
  def mount(_, _, socket) do
    socket = assign(socket, page_title: "Training Schedule")

    if connected?(socket) do
      Endpoint.subscribe("workouts:#{socket.assigns.user.id}")
      {:ok, assign(socket, :time_zone, get_connect_params(socket)["time_zone"])}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
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
      params when map_size(params) > 0 ->
        {:noreply, action(socket, socket.assigns.live_action, params)}

      _ ->
        if connected?(socket) do
          {:noreply, redirect_to_user_tz_range(socket)}
        else
          {:noreply, load_with_default_range(socket)}
        end
    end)
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, load_workouts(socket)}

  @impl true
  def handle_event("move", %{"workout" => id, "target" => date}, socket) do
    Workouts.update(id, %{date: date})
    {:noreply, load_workouts(socket)}
  end

  def handle_event("delete", data, socket) do
    Workouts.delete(data)
    {:noreply, load_workouts(socket)}
  end

  def handle_event("create", data, socket) do
    data
    |> Enum.map(fn %{"destination" => date, "template" => json} ->
      json
      |> Jason.decode!()
      |> Map.merge(%{"date" => date, "user_id" => socket.assigns.user.id})
    end)
    |> Workouts.batch_insert_from_copy_templates()

    {:noreply, load_workouts(socket)}
  end

  defp load_with_default_range(socket) do
    {from, to} = date_range(Date.utc_today())
    load_between(socket, from, to)
  end

  defp redirect_to_user_tz_range(socket) do
    now =
      case DateTime.now(socket.assigns.time_zone) do
        {:ok, time} -> time
        _ -> Date.utc_today()
      end

    {from, to} = date_range(now)
    push_patch(socket, to: ~p"/schedule?from=#{from}&to=#{to}", replace: true)
  end

  defp date_range(now) do
    from = now |> Date.beginning_of_week()
    to = Date.add(from, @schedule_days)
    {from, to}
  end

  defp redirect_to_default_url(socket) do
    from = Date.utc_today() |> Date.beginning_of_week()
    to = Date.add(from, @schedule_days)
    push_patch(socket, to: ~p"/schedule?from=#{from}&to=#{to}", replace: true)
  end

  defp action(socket, :index, %{"from" => from, "to" => to}) do
    maybe_load_between(socket, from, to)
  end

  defp action(socket, :new, params) do
    socket
    |> maybe_load_between(params["from"], params["to"])
    |> assign(:date, params["date"])
  end

  defp action(socket, :edit, params) do
    socket
    |> maybe_load_between(params["from"], params["to"])
    |> assign(:form_id, params["id"])
  end

  defp action(socket, _, _), do: redirect_to_default_url(socket)

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
    |> assign(:back, from |> Date.beginning_of_week() |> Date.add(-7))
    |> assign(:forward, to |> Date.end_of_week() |> Date.add(7))
    |> load_workouts()
  end

  defp load_workouts(socket) do
    %{from: from, to: to, user: user} = socket.assigns

    user.id
    |> Workouts.user_workouts(from, to)
    |> Cycles.group_workouts(Date.beginning_of_week(from), Date.end_of_week(to), 7)
    |> then(&assign(socket, :cycles, &1))
  end

  attr :rest, :global
  attr :patch, :string, required: true
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      class={
        ~w(mx-2 mt-5 mb-4 inline-block rounded-full bg-gray-300 px-4 py-2 text-gray-500 hover:ring-2 dark:bg-gray-500 dark:text-gray-100)
      }
      patch={@patch}
      replace
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
