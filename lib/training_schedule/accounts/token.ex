defmodule TrainingSchedule.Accounts.Token do
  @moduledoc """
  Access tokens.

  To enable revoking logins in the future, login sessions are tied to tokens. When a user logs in,
  they receive a token, which uniquely identifies the user.
  """
  use Ecto.Schema
  alias TrainingSchedule.Repo

  # Token generation constants.
  # A database migration is required if changing either of these!
  @challenge_size 32
  @id_size 16

  @id_alphabet Enum.concat([?0..?9, ?a..?z, ?A..?Z])

  @type t :: binary()

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "tokens" do
    belongs_to :user, TrainingSchedule.Accounts.User
    field :challenge, :binary, redact: true
    timestamps()
  end

  @spec create(integer()) :: t()
  def create(user_id) do
    id = for _ <- 1..@id_size, into: "", do: <<Enum.random(@id_alphabet)>>
    challenge = :crypto.strong_rand_bytes(@challenge_size)

    Repo.insert!(%__MODULE__{id: id, user_id: user_id, challenge: challenge})
    id <> challenge
  end

  @spec drop(t()) :: :ok
  def drop(<<id::binary-size(@id_size), _::binary>>) do
    Repo.delete(%__MODULE__{id: id})
    :ok
  end

  @spec to_user_id(t()) :: {:ok, integer()} | :error
  def to_user_id(<<id::binary-size(@id_size), c::binary-size(@challenge_size)>>) do
    case Repo.get(__MODULE__, id) do
      %__MODULE__{user_id: id, challenge: challenge} when challenge == c -> {:ok, id}
      _ -> :error
    end
  end

  def to_user_id(_), do: :error
end
