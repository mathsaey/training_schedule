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

defmodule TrainingSchedule.Accounts.User do
  @moduledoc """
  User information.

  This module defines the schema which stores the information associated with a user, such as
  their credentials and preferences.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field :username, :string
    field :admin?, :boolean, default: false
    field :password_hash, :string, redact: true
    field :password, :string, virtual: true, redact: true

    has_many :workout_types, TrainingSchedule.Workouts.Type
    has_many :workouts, TrainingSchedule.Workouts.Workout

    timestamps()
  end

  @spec changeset(t(), %{String.t() => any()} | %{atom() => any()}) :: Ecto.Changeset.t()
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:username, :password, :admin?])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 3, max: 50)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:username)
    |> hash()
  end

  @spec valid_password?(t() | nil, String.t()) :: boolean()
  # Prevent timing attacks: if the user is invalid, we still run the hash function to ensure the
  # non-existence of the user cannot be inferred.
  def valid_password?(nil, _), do: Argon2.no_user_verify()
  def valid_password?(%__MODULE__{password_hash: hash}, pw), do: Argon2.verify_pass(pw, hash)

  defp hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :password_hash, Argon2.hash_pwd_salt(pw))
  end

  defp hash(cs), do: cs
end
