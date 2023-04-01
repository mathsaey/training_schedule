defmodule TrainingSchedule.Workouts do
  @moduledoc """
  Workouts context.

  This context groups most of the functionality related to workouts.
  """

  import Ecto.Query, except: [update: 2]
  alias TrainingSchedule.{PubSub, Repo}

  alias TrainingSchedule.Accounts.User
  alias TrainingSchedule.Workouts.{Type, Workout}

  def user_types(%User{id: id}), do: user_types(id)

  def user_types(user_id) do
    from(t in Type, where: t.user_id == ^user_id, order_by: t.name)
    |> Repo.all()
    |> Enum.map(&Type.derive_template_fields/1)
  end

  def type_by_id(id) do
    from(t in Type, where: t.id == ^id)
    |> Repo.one()
    |> Type.derive_template_fields()
  end

  def type_by_name(user_id, name) do
    from(t in Type, where: t.name == ^name and t.user_id == ^user_id)
    |> Repo.one()
    |> Type.derive_template_fields()
  end

  defp types_by_ids(ids) do
    from(t in Type, where: t.id in ^ids)
    |> Repo.all()
    |> Enum.map(&Type.derive_template_fields/1)
  end

  def type_changeset(type, attrs \\ %{}), do: Type.changeset(type, attrs)

  def create_type!(type \\ %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.insert!()
    |> then(&maybe_broadcast({:ok, &1}, :types, :create))
  end

  def create_type(type \\ %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.insert()
    |> maybe_broadcast(:types, :create)
  end

  def update_type(id, attrs) when is_integer(id), do: id |> type_by_id() |> update_type(attrs)

  def update_type(type = %Type{}, attrs) do
    type
    |> IO.inspect()
    |> Type.changeset(attrs)
    |> Repo.update()
    |> maybe_broadcast(:types, :update)
    |> IO.inspect()
  end

  def delete_type(id) when is_integer(id), do: id |> type_by_id() |> delete_type()

  def delete_type(type = %Type{}) do
    type
    |> Repo.delete()
    |> maybe_broadcast(:types, :delete)
  end

  def dummy_type(user) do
    Ecto.build_assoc(
      user,
      :workout_types,
      name: "Workout",
      color: "#0e7490",
      temlate: "",
      template_fields: []
    )
  end

  def user_workouts(%User{id: id}, from, to), do: user_workouts(id, from, to)

  def user_workouts(user_id, from, to) when is_integer(user_id) do
    from(
      w in Workout,
      where: w.user_id == ^user_id and ^from <= w.date and w.date <= ^to,
      preload: [type: ^(&types_by_ids/1)],
      order_by: w.date
    )
    |> Repo.all()
    |> Enum.map(&Workout.derive_description/1)
  end

  def get(id) do
    from(w in Workout, where: w.id == ^id, preload: :type)
    |> Repo.one()
    |> Workout.derive_description()
    |> Map.update!(:type, &Type.derive_template_fields/1)
  end

  def changeset(workout, attrs \\ %{}), do: Workout.changeset(workout, attrs)

  def duplicate(workout = %Workout{}), do: Workout.duplicate(workout)
  def duplicate(id), do: id |> get() |> Workout.duplicate()

  def create!(wo \\ %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.insert!()
    |> then(&maybe_broadcast({:ok, &1}, :workouts, :create))
  end

  def create(wo \\ %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.insert()
    |> maybe_broadcast(:workouts, :create)
  end

  def update(id, attrs) when is_integer(id), do: id |> get() |> update(attrs)

  def update(wo = %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.update()
    |> maybe_broadcast(:workouts, :update)
  end

  def delete(id) when is_integer(id), do: id |> get() |> Repo.delete()

  def delete(workout = %Workout{}) do
    workout
    |> Repo.delete()
    |> maybe_broadcast(:workouts, :delete)
  end

  def dummy(user), do: Ecto.build_assoc(user, :workouts, type: dummy_type(user))

  defp maybe_broadcast(t = {:error, _}, _, _), do: t

  defp maybe_broadcast(t = {:ok, item}, topic, action) do
    Phoenix.PubSub.broadcast(PubSub, "workouts:#{item.user_id}", {topic, action, item})
    t
  end
end
