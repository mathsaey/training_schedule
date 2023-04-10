defmodule TrainingScheduleWeb.ShareLive do
  use TrainingScheduleWeb, :live_view

  alias TrainingSchedule.Shares
  alias TrainingSchedule.Shares.Share
  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Cycles

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Shares.get(id) do
      nil ->
        socket
        |> put_flash(:error, "That share does not exist")
        |> assign(share: nil, cycles: [])
        |> then(&{:ok, &1})

      share = %Share{user_id: user_id} ->
        if connected?(socket), do: Endpoint.subscribe("workouts:#{user_id}")
        {:ok, socket |> assign(share: share) |> load_workouts(share)}
    end
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket |> load_workouts(socket.assigns.share)}

  defp load_workouts(socket, %Share{user_id: user_id, from: from, to: to}) do
    Workouts.user_workouts(user_id, from, to)
    |> Cycles.group_workouts(Date.beginning_of_week(from), Date.end_of_week(to), 7)
    |> then(&assign(socket, :cycles, &1))
  end
end
