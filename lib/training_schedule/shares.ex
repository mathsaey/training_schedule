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
  alias TrainingSchedule.Repo
  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Shares.Share

  def create(share \\ %Share{}, attrs) do
    share
    |> Share.changeset(attrs)
    |> Repo.insert()
  end

  def get(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} -> Repo.one(from s in Share, where: s.id == ^uuid)
      :error -> nil
    end
  end

  def workouts_for(uuid) do
    share = get(uuid)
    Workouts.user_workouts(share.user_id, share.from, share.to)
  end
end
