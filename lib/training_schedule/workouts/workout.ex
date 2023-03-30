defmodule TrainingSchedule.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset
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
  # TODO: ensure this can accept integers
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:date, :description_fields, :distance, :type_id, :user_id])
    |> validate_required([:date, :distance, :type_id, :user_id])
    # |> update_change(:distance, &(&1 * 1.0)) # TODO: doesn't seem to fix things
    |> assoc_constraint(:type)
    |> assoc_constraint(:user)
  end

  def duplicate(workout = %__MODULE__{}) do
    %__MODULE__{
      date: workout.date,
      distance: workout.distance,
      description_fields: workout.description_fields,
      user_id: workout.user_id,
      type_id: workout.type_id,
      type: workout.type,
      user: workout.user
    }
  end

  def derive_description(cs = %Ecto.Changeset{valid?: true, changes: %{description_fields: f}}) do
    change(cs, description: Template.expand(get_field(cs, :type).template, f))
  end

  def derive_description(cs = %Ecto.Changeset{}), do: cs

  def derive_description(workout = %__MODULE__{description: nil}) do
    expand = Template.expand(workout.type.template, workout.description_fields)
    %{workout | description: expand}
  end

  def derive_description(workout = %__MODULE__{}), do: workout
end
