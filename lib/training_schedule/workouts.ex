defmodule TrainingSchedule.Workouts do
  @moduledoc """
  Workouts context.

  This context groups most of the functionality related to workouts.
  """
  import Ecto.Query, except: [update: 2]
  alias TrainingSchedule.{PubSub, Repo}

  alias TrainingSchedule.Accounts.User
  alias TrainingSchedule.Workouts.{Type, TypeCache, Workout}

  def user_types(%User{id: id}), do: user_types(id)
  def user_types(user_id), do: TypeCache.fetch_user_types(user_id)

  def type_by_id(%User{id: user_id}, type_id), do: type_by_id(user_id, type_id)
  def type_by_id(user_id, type_id), do: TypeCache.fetch_type_by_id(user_id, type_id)

  def type_by_name(%User{id: id}, name), do: type_by_name(id, name)
  def type_by_name(user_id, name), do: TypeCache.fetch_type_by_name(user_id, name)

  def type_changeset(type, attrs \\ %{}), do: Type.changeset(type, attrs)

  def create_type!(type \\ %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.insert!()
    |> then(&after_type_change({:ok, &1}, :create))
  end

  def create_type(type \\ %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.insert()
    |> after_type_change(:create)
    |> maybe_broadcast(:types, :create)
  end

  def update_type(type = %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.update()
    |> after_type_change(:update)
  end

  def delete_type(type = %Type{}) do
    type
    |> Repo.delete()
    |> after_type_change(:delete)
  end

  def dummy_type(user, attrs \\ []) do
    defaults = [name: "Workout", color: "#0e7490", template: "", template_fields: []]
    attrs = Keyword.merge(defaults, attrs)

    user
    |> Ecto.build_assoc(:workout_types, attrs)
    |> Type.derive_template_fields()
  end

  def user_workouts(%User{id: id}, from, to), do: user_workouts(id, from, to)

  def user_workouts(user_id, from, to) when is_integer(user_id) do
    from(
      w in Workout,
      where: w.user_id == ^user_id and ^from <= w.date and w.date <= ^to,
      preload: [type: ^fn _ -> user_types(user_id) end],
      order_by: w.date
    )
    |> Repo.all()
    |> Enum.map(&Workout.derive_description/1)
  end

  def get(id) do
    from(w in Workout, where: w.id == ^id, preload: [:type])
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
    |> Workout.derive_description()
    |> then(&maybe_broadcast({:ok, &1}, :workouts, :create))
  end

  def create(wo \\ %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.insert()
    |> maybe_derive_description()
    |> maybe_broadcast(:workouts, :create)
  end

  def update(id, attrs) when is_integer(id), do: id |> get() |> update(attrs)

  def update(wo = %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.update()
    |> maybe_derive_description()
    |> maybe_broadcast(:workouts, :update)
  end

  def delete(id) when is_integer(id), do: id |> get() |> Repo.delete()

  def delete(workout = %Workout{}) do
    workout
    |> Repo.delete()
    |> maybe_broadcast(:workouts, :delete)
  end

  def dummy(user, attrs \\ []) do
    attrs = Keyword.put_new_lazy(attrs, :type, fn -> dummy_type(user) end)

    user
    |> Ecto.build_assoc(:workouts, attrs)
    |> Workout.derive_description()
  end

  defp maybe_derive_description({:ok, workout}), do: {:ok, Workout.derive_description(workout)}
  defp maybe_derive_description(t = {:error, _}), do: t

  defp after_type_change(tup, action) do
    tup
    |> maybe_invalidate_type_cache()
    |> maybe_broadcast(:types, action)
  end

  defp maybe_invalidate_type_cache(t = {:error, _}), do: t

  defp maybe_invalidate_type_cache(t = {:ok, %Type{user_id: user_id}}) do
    TypeCache.invalidate(user_id)
    t
  end

  defp maybe_broadcast(t = {:error, _}, _, _), do: t

  defp maybe_broadcast(t = {:ok, item}, topic, action) do
    Phoenix.PubSub.broadcast(PubSub, "workouts:#{item.user_id}", {topic, action, item})
    t
  end
end
