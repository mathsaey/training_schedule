defmodule TrainingSchedule.Accounts.User do
  use Ecto.Schema
  import Ecto.Query, except: [update: 2]
  import Ecto.Changeset

  alias TrainingSchedule.Repo

  schema "users" do
    field :username, :string
    field :admin?, :boolean, default: false
    field :password_hash, :string, redact: true
    field :password, :string, virtual: true, redact: true

    has_many :workout_types, TrainingSchedule.Workouts.Type
    has_many :workouts, TrainingSchedule.Workouts.Workout

    timestamps()
  end

  def get(id), do: Repo.one(from u in __MODULE__, where: u.id == ^id)
  def get_by_name(username), do: Repo.one(from u in __MODULE__, where: u.username == ^username)

  def create(attrs), do: %__MODULE__{} |> changeset(attrs) |> Repo.insert()
  def create!(attrs), do: %__MODULE__{} |> changeset(attrs) |> Repo.insert!()

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:username, :password, :admin?])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 3, max: 50)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:username)
    |> hash()
  end

  def authenticate(username, password) do
    username
    |> get_by_name()
    |> Argon2.check_pass(password)
    |> case do
      {:ok, user} -> {:ok, user}
      _ -> :error
    end
  end

  defp hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    change(cs, Argon2.add_hash(pw))
  end

  defp hash(cs), do: cs
end
