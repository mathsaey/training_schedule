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
