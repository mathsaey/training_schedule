defmodule TrainingSchedule.Workouts do
  import Ecto.Query
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
    |> Type.changeset(attrs)
    |> Repo.update()
    |> maybe_broadcast(:types, :update)
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
      color: "#D97706",
      template: "{reps}x{distance}@{speed}"
    )
  end

  def list_user_workouts(user, from, to) do
    user |> user_workouts() |> workouts_between(from, to) |> Repo.all()
  end

  def get(id), do: Repo.one(from w in Workout, where: w.id == ^id)
  def changeset(workout, attrs \\ %{}), do: Workout.changeset(workout, attrs)

  def duplicate(workout = %Workout{}), do: Workout.duplicate(workout)
  def duplicate(id), do: id |> get() |> Workout.duplicate()

  def create(wo \\ %Workout{}, attrs), do: wo |> Workout.changeset(attrs) |> Repo.insert()
  def create!(wo \\ %Workout{}, attrs), do: wo |> Workout.changeset(attrs) |> Repo.insert!()

  def update(wo = %Workout{}, attrs), do: wo |> Workout.changeset(attrs) |> Repo.update()
  def update(id, attrs), do: id |> get() |> Workout.changeset(attrs) |> Repo.update()

  def delete(workout = %Workout{}), do: workout |> Repo.delete()
  def delete(id), do: id |> get() |> Repo.delete()

  defdelegate derive_description(workout), to: Workout

  defp user_workouts(%User{id: id}), do: user_workouts(id)

  defp user_workouts(user_id) do
    from(w in Workout, where: w.user_id == ^user_id, order_by: w.date, preload: :type)
  end

  defp workouts_between(q, from, to), do: q |> where([w], ^from <= w.date and w.date <= ^to)

  defp maybe_broadcast(t = {:error, _}, _, _), do: t

  defp maybe_broadcast(t = {:ok, type}, topic, action) do
    Phoenix.PubSub.broadcast(PubSub, "workout_types:#{type.user_id}", {topic, action, type})
    t
  end

end
