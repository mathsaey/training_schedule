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

defmodule TrainingSchedule.Shares.Share do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "shares" do
    field :name, :string
    field :from, :date
    field :to, :date

    belongs_to :user, TrainingSchedule.Accounts.User

    timestamps()
  end

  def changeset(share, attrs) do
    share
    |> cast(attrs, [:name, :from, :to, :user_id])
    |> validate_required([:name, :from, :to, :user_id])
    |> validate_length(:name, min: 3, max: 255)
    |> validate_dates()
    |> assoc_constraint(:user)
  end

  defp validate_dates(changeset) do
    if changeset.valid? and (changed?(changeset, :from) or changed?(changeset, :to)) do
      from = fetch_field!(changeset, :from)
      to = fetch_field!(changeset, :to)

      if Date.compare(to, from) == :gt do
        changeset
      else
        add_error(changeset, :to, "must be after \"from\" date")
      end
    else
      changeset
    end
  end
end
