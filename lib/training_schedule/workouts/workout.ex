defmodule TrainingSchedule.Workouts.Workout do
  @moduledoc """
  Workout schema.

  A training schedule consists of several workouts, represented in this schema.
  """
  use Ecto.Schema
  alias Ecto.Changeset
  import Ecto.Changeset

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Workouts.Template

  @typedoc """
  This struct represents a workout.

  Care should be taken to ensure the `:description` field of this struct remains consistent with
  the `:template` of the `:type` associated with the workout and with the `:description_fields`
  field. The `changeset/2` function ensures this happens automatically if the changeset is valid.
  """
  @type t :: %__MODULE__{}

  schema "workouts" do
    field :date, :date
    field :distance, :float
    field :description_fields, {:map, :string}
    field :description, :string, virtual: true

    belongs_to :user, TrainingSchedule.Accounts.User
    belongs_to :type, TrainingSchedule.Workouts.Type
  end

  @doc """
  Copy an existing workout.

  Creates a new workout identical to an existing workout. Only the id will not be copied.
  """
  @spec duplicate(t()) :: t()
  def duplicate(workout = %__MODULE__{}) do
    %__MODULE__{
      date: workout.date,
      distance: workout.distance,
      description_fields: workout.description_fields,
      description: workout.description,
      user_id: workout.user_id,
      type_id: workout.type_id,
      type: workout.type,
      user: workout.user
    }
  end

  @spec changeset(t(), %{String.t() => any()} | %{atom() => any()}) :: Changeset.t()
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:date, :description_fields, :distance, :type_id, :user_id])
    |> validate_required([:date, :distance, :type_id, :user_id])
    |> assoc_constraint(:type)
    |> assoc_constraint(:user)
    |> change_description()
  end

  defp change_description(cs = %Ecto.Changeset{valid?: true, changes: changes}) do
    if Map.has_key?(changes, :type_id) or Map.has_key?(changes, :description_fields) do
      user_id = get_field(cs, :user_id)
      type_id = get_field(cs, :type_id)
      fields = get_field(cs, :description_fields)
      type = Workouts.type_by_id(user_id, type_id)
      change(cs, description: Template.expand(type.template, fields))
    else
      cs
    end
  end

  defp change_description(cs = %Ecto.Changeset{}), do: cs

  @spec derive_description(t()) :: t()
  def derive_description(workout = %__MODULE__{description: nil}) do
    expand = Template.expand(workout.type.template, workout.description_fields)
    %{workout | description: expand}
  end

  def derive_description(workout = %__MODULE__{}), do: workout

  def derive_description(nil), do: nil
end
