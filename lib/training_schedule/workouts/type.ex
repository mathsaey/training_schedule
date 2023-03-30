defmodule TrainingSchedule.Workouts.Type do
  use Ecto.Schema
  import Ecto.Changeset
  alias TrainingSchedule.Workouts.Template

  @derive {Phoenix.Param, key: :name}
  schema "types" do
    field :name, :string
    field :color, :string
    field :template, :string
    field :template_fields, {:array, :string}, virtual: true

    belongs_to :user, TrainingSchedule.Accounts.User
    has_many :workouts, TrainingSchedule.Workouts.Workout
  end

  @doc false
  def changeset(type, attrs) do
    type
    |> cast(attrs, [:name, :color, :template, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 2, max: 60)
    |> validate_length(:template, max: 140)
    |> validate_change(:template, &validate_template/2)
    |> validate_format(:color, ~r/^#[0-9a-fA-F]{6}$/)
    |> unique_constraint([:user_id, :name])
  end

  def validate_template(field, template) do
    case Template.validate(template) do
      :ok -> []
      {:error, rem} -> [{field, "Invalid template string: #{rem}"}]
    end
  end

  def derive_template_fields(cs = %Ecto.Changeset{valid?: true, changes: %{template: t}}) do
    {:ok, fields} = Template.get_fields(t)
    change(cs, template_fields: fields)
  end

  def derive_template_fields(cs = %Ecto.Changeset{}), do: cs

  def derive_template_fields(type = %__MODULE__{template_fields: [_ | _]}), do: type

  def derive_template_fields(type = %__MODULE__{template: template}) do
    {:ok, fields} = Template.get_fields(template)
    %{type | template_fields: fields}
  end
end
