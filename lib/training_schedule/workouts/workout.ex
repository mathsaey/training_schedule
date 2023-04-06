defmodule TrainingSchedule.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Workouts.Template

  schema "workouts" do
    field :date, :date
    field :distance, :float
    field :description_fields, {:map, :string}
    field :description, :string, virtual: true

    belongs_to :user, TrainingSchedule.Accounts.User
    belongs_to :type, TrainingSchedule.Workouts.Type
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:date, :description_fields, :distance, :type_id, :user_id])
    |> validate_required([:date, :distance, :type_id, :user_id])
    |> assoc_constraint(:type)
    |> assoc_constraint(:user)
    |> change_description()
  end

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

  def derive_description(workout = %__MODULE__{description: nil}) do
    expand = Template.expand(workout.type.template, workout.description_fields)
    %{workout | description: expand}
  end

  def derive_description(workout = %__MODULE__{}), do: workout
end
