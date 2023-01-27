defmodule TrainingSchedule.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  alias TrainingSchedule.Repo

  # These values are also encoded in the database.
  @challenge_size 32
  @id_size 16

  @id_alphabet Enum.concat([?0..?9, ?a..?z, ?A..?Z])

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "user_tokens" do
    belongs_to :user, TrainingSchedule.Accounts.User
    field :challenge, :binary, redact: true
    timestamps()
  end

  def create(user_id) do
    id = for _ <- 1..@id_size, into: "", do: <<Enum.random(@id_alphabet)>>
    challenge = :crypto.strong_rand_bytes(@challenge_size)

    Repo.insert!(%__MODULE__{id: id, user_id: user_id, challenge: challenge})
    id <> challenge
  end

  def drop(<<id::binary-size(@id_size), _::binary>>) do
    Repo.delete(%__MODULE__{id: id})
    :ok
  end

  def drop_all(user_id) do
    Repo.delete_all(from t in __MODULE__, where: t.user_id == ^user_id)
    :ok
  end

  def to_user_id(<<id::binary-size(@id_size), c::binary-size(@challenge_size)>>) do
    case Repo.get(__MODULE__, id) do
      %__MODULE__{user_id: id, challenge: challenge} when challenge == c -> {:ok, id}
      _ -> :error
    end
  end

  def to_user_id(_), do: :error
end
