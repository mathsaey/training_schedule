defmodule TrainingSchedule.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset
  alias TrainingSchedule.Workouts.Template

  schema "workouts" do
    field :date, :date
    field :distance, :integer
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
  end

  def derive_description(workout = %__MODULE__{}) do
    expand = Template.expand(workout.type.template, workout.description_fields)
    %{workout | description: expand}
  end
end
