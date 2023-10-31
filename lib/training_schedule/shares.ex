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

defmodule TrainingSchedule.Shares do
  import Ecto.Query
  alias TrainingSchedule.{PubSub, Repo, Workouts, Shares.Share, Accounts.User}

  def create(user_id, attrs) do
    %Share{user_id: user_id}
    |> Share.changeset(attrs)
    |> Repo.insert()
  end

  def changeset(share \\ %Share{}, attrs \\ %{}), do: Share.changeset(share, attrs)

  def delete(uuid), do: uuid |> get() |> Repo.delete() |> maybe_broadcast(:delete)

  def safe_delete(uuid, user_id) do
    share = get(uuid) |> IO.inspect()

    if user_id == share.user_id do
      share |> Repo.delete() |> maybe_broadcast(:delete)
    end
  end

  def update(share, attrs) do
    share
    |> Share.changeset(attrs)
    |> Repo.update()
    |> maybe_broadcast(:update)
  end

  def get(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} -> Repo.one(from s in Share, where: s.id == ^uuid)
      :error -> nil
    end
  end

  def user_shares(%User{id: id}), do: user_shares(id)
  def user_shares(id), do: Repo.all(from s in Share, where: s.user_id == ^id)

  def workouts_for(uuid) do
    share = get(uuid)
    Workouts.user_workouts(share.user_id, share.from, share.to)
  end

  defp maybe_broadcast(t = {:error, _}, _), do: t

  defp maybe_broadcast(t = {:ok, share}, action) do
    Phoenix.PubSub.broadcast(PubSub, "shares:#{share.id}", {:shares, action, share})
    t
  end
end
