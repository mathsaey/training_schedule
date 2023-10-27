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

defmodule TrainingSchedule.Repo.Migrations.CreateUsersTypesWorkouts do
  use Ecto.Migration

  def change do
    create table("users") do
      add :username, :string, size: 50
      add :admin?, :boolean
      # length of the hash returned by Argon2
      add :password_hash, :string, size: 97

      timestamps()
    end

    create table("tokens", primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false, size: 16
      add :user_id, references("users", on_delete: :delete_all)
      add :challenge, :binary, null: false, size: 32

      timestamps()
    end

    create table(:types) do
      add :user_id, references("users", on_delete: :delete_all)

      add :name, :string, size: 60, null: false
      add :color, :string, size: 7
      add :template, :string, null: false, default: "", size: 140
    end

    create table(:workouts) do
      add :user_id, references("users", on_delete: :delete_all)
      add :type_id, references("types", on_delete: :delete_all)

      add :date, :date, null: false
      add :distance, :float, null: false
      add :description_fields, :map
    end

    create unique_index(:users, [:username])
    create unique_index(:types, [:user_id, :name])

    create index(:types, :user_id)
    create index(:workouts, [:user_id, :date])
  end
end
