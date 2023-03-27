defmodule TrainingSchedule.Workouts do
  import Ecto.Query
  alias TrainingSchedule.Repo

  alias TrainingSchedule.Accounts.User
  alias TrainingSchedule.Workouts.{Type, Workout}

  def list_user_types(%User{id: id}), do: list_user_types(id)

  def list_user_types(user_id) do
    Repo.all(from t in Type, where: t.user_id == ^user_id, order_by: t.name)
  end

  def get_type(id), do: Repo.one(from t in Type, where: t.id == ^id)

  def get_type_by_name(user_id, name) do
    Repo.one(from t in Type, where: t.name == ^name and t.user_id == ^user_id)
  end

  def type_changeset(type, attrs \\ %{}), do: Type.changeset(type, attrs)

  def create_type!(type \\ %Type{}, attrs), do: type |> Type.changeset(attrs) |> Repo.insert!()
  def create_type(type \\ %Type{}, attrs), do: type |> Type.changeset(attrs) |> Repo.insert()

  def update_type(type = %Type{}, attrs), do: type |> Type.changeset(attrs) |> Repo.update()
  def update_type(id, attrs), do: id |> get_type() |> update_type(attrs)

  def delete_type(type = %Type{}), do: Repo.delete(type)
  def delete_type(id), do: id |> get_type() |> delete_type()

  defdelegate derive_type_template_fields(type), to: Type, as: :derive_template_fields

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
end
