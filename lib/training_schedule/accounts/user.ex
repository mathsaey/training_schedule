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
  def valid_password?(user, password) do
    match?({:ok, _user}, Argon2.check_pass(user, password))
  end

  defp hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    change(cs, Argon2.add_hash(pw))
  end

  defp hash(cs), do: cs
end
