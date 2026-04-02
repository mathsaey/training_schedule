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

defmodule TrainingScheduleWeb.ShareLive.Manager do
  use TrainingScheduleWeb, :live_view
  alias TrainingSchedule.Shares

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> load_shares()
     |> assign(:edit, nil)
     |> assign(:changeset, Shares.changeset())}
  end

  @impl true
  def handle_event("delete", %{"share-id" => id}, socket) do
    Shares.delete(id, socket.assigns.user.id)
    {:noreply, load_shares(socket)}
  end

  @impl true
  def handle_event("edit", %{"share-id" => id}, socket) do
    share = Shares.get(id)

    {:noreply,
     socket
     |> assign(:edit, share)
     |> assign(:changeset, Shares.changeset(share))}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, socket |> assign(:edit, nil) |> assign(:changeset, Shares.changeset())}
  end

  def handle_event("update", %{"share" => params}, socket) do
    case Shares.update(socket.assigns.edit, socket.assigns.user.id, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> load_shares()
         |> assign(:edit, nil)
         |> assign(:changeset, Shares.changeset())}

      {:error, cs} ->
        {:noreply, assign(socket, :changeset, cs)}
    end
  end

  def handle_event("create", %{"share" => params}, socket) do
    case Shares.create(socket.assigns.user.id, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:shares, load_shares(socket))
         |> assign(:changeset, Shares.changeset())}

      {:error, cs} ->
        {:noreply, assign(socket, :changeset, cs)}
    end
  end

  defp load_shares(socket) do
    {infinite, timed} =
      socket.assigns.user
      |> Shares.user_shares()
      |> Enum.split_with(&is_nil(&1.from))

    socket
    |> assign(:timed_shares, timed)
    |> assign(:infinite_shares, infinite)
  end
end
