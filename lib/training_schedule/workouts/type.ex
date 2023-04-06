defmodule TrainingSchedule.Workouts.Type do
  @moduledoc """
  Workout type schema.

  A training schedule generally consists of several different workouts, such as easy runs,
  recovery runs, interval sessions, long runs or races. This module defines an ecto schema to
  represent such a training type. Each type of workout has its own name, color and
  `TrainingSchedule.Workouts.Template`.
  """

  use Ecto.Schema
  alias Ecto.Changeset
  import Ecto.Changeset

  alias TrainingSchedule.Workouts.Template

  @typedoc """
  This struct represents a workout type.

  Care should be taken to ensure the `:template_fields` of this struct remain consistent with its
  `:template`. The `changeset/2` function ensure this happens automatically (if the changeset is
  valid). When a workout is fetched from the database, `derive_template_fields/1` should be used
  to ensure the template fields are stored inside the struct.
  """
  @type t :: %__MODULE__{}

  @derive {Phoenix.Param, key: :name}
  schema "types" do
    field :name, :string
    field :color, :string
    field :template, :string, default: ""
    field :template_fields, {:array, :string}, virtual: true

    belongs_to :user, TrainingSchedule.Accounts.User
    has_many :workouts, TrainingSchedule.Workouts.Workout
  end

  @spec changeset(t(), %{String.t() => any()} | %{atom() => any()}) :: Changeset.t()
  def changeset(type, attrs) do
    type
    |> cast(attrs, [:name, :color, :template, :user_id])
    |> validate_required([:name, :user_id, :color])
    |> validate_length(:name, min: 2, max: 60)
    |> validate_length(:template, max: 140)
    |> validate_change(:template, &validate_template/2)
    |> validate_format(:color, ~r/^#[0-9a-fA-F]{6}$/)
    |> unique_constraint([:user_id, :name], error_key: :name)
    |> change_template_fields()
  end

  defp validate_template(field, template) do
    case Template.validate(template) do
      :ok -> []
      {:error, rem} -> [{field, "invalid template string: #{rem}"}]
    end
  end

  defp change_template_fields(cs = %Changeset{valid?: true, changes: %{template: t}}) do
    {:ok, fields} = Template.get_fields(t)
    put_change(cs, :template_fields, fields)
  end

  defp change_template_fields(cs = %Changeset{}), do: cs

  @spec derive_template_fields(t()) :: t()
  def derive_template_fields(type = %__MODULE__{template: template}) do
    {:ok, fields} = Template.get_fields(template)
    %{type | template_fields: fields}
  end
end
