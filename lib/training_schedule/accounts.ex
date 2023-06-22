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

defmodule TrainingSchedule.Accounts do
  @moduledoc """
  Accounts context
  """
  alias __MODULE__.{User, Token}
  alias TrainingSchedule.Repo
  alias Ecto.Changeset

  import Ecto.Query

  @spec by_id(integer()) :: User.t() | nil
  def by_id(id), do: Repo.one(from u in User, where: u.id == ^id)

  @spec by_username(String.t()) :: User.t() | nil
  def by_username(username), do: Repo.one(from u in User, where: u.username == ^username)

  @spec create(%{String.t() => any()} | %{atom() => any()}) ::
          {:ok, User.t()} | {:error, Changeset.t()}
  def create(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()

  @spec create!(%{String.t() => any()} | %{atom() => any()}) ::
          User.t() | no_return()
  def create!(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert!()

  @spec authenticate(String.t(), String.t()) :: {:ok, Token.t()} | :error
  def authenticate(username, password) do
    account = by_username(username)

    if User.valid_password?(account, password) do
      {:ok, Token.create(account.id)}
    else
      :error
    end
  end

  defdelegate token_to_user_id(token), to: Token, as: :to_user_id
  defdelegate revoke_token(token), to: Token, as: :drop
end
