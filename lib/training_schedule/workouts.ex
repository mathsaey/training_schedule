# TrainingSchedule.ex
# Copyright (c) 2023, Mathijs Saey

# TrainingSchedule.ex is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# TrainingSchedule.ex is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

defmodule TrainingSchedule.Workouts do
  @moduledoc """
  Workouts context.

  This context groups most of the functionality related to workouts.
  """
  import Ecto.Query, except: [update: 2]
  alias Ecto.Changeset

  alias TrainingSchedule.Accounts.User
  alias TrainingSchedule.{PubSub, Repo}
  alias TrainingSchedule.Workouts.{Type, TypeCache, Workout}

  @spec user_types(integer() | User.t()) :: [Type.t()]
  def user_types(%User{id: id}), do: user_types(id)
  def user_types(user_id), do: TypeCache.fetch_user_types(user_id)

  @spec type_by_id(integer() | User.t(), integer()) :: Type.t() | nil
  def type_by_id(%User{id: user_id}, type_id), do: type_by_id(user_id, type_id)
  def type_by_id(user_id, type_id), do: TypeCache.fetch_type_by_id(user_id, type_id)

  @spec type_by_name(integer() | User.t(), String.t()) :: Type.t() | nil
  def type_by_name(%User{id: id}, name), do: type_by_name(id, name)
  def type_by_name(user_id, name), do: TypeCache.fetch_type_by_name(user_id, name)

  @spec type_changeset(Type.t(), %{String.t() => any()} | %{atom() => any()}) :: Changeset.t()
  def type_changeset(type, attrs \\ %{}), do: Type.changeset(type, attrs)

  @spec create_type!(Type.t(), %{String.t() => any()} | %{atom() => any()}) ::
          Type.t() | no_return()
  def create_type!(type \\ %Type{}, attrs) do
    type =
      type
      |> Type.changeset(attrs)
      |> Repo.insert!()

    after_type_change({:ok, type}, :create)
    type
  end

  @spec create_type(Type.t(), %{String.t() => any()} | %{atom() => any()}) ::
          {:ok, Type.t()} | {:error, Changeset.t()}
  def create_type(type \\ %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.insert()
    |> after_type_change(:create)
    |> maybe_broadcast(:types, :create)
  end

  @spec update_type(Type.t(), %{String.t() => any()} | %{atom() => any()}) ::
          {:ok, Type.t()} | {:error, Changeset.t()}
  def update_type(type = %Type{}, attrs) do
    type
    |> Type.changeset(attrs)
    |> Repo.update()
    |> after_type_change(:update)
  end

  @spec delete_type(Type.t()) :: {:ok, Type.t()} | {:error, Changeset.t()}
  def delete_type(type = %Type{}) do
    type
    |> Repo.delete()
    |> after_type_change(:delete)
  end

  @doc """
  Create a dummy placeholder type.

  Creates a dummy type, which can be used as a placeholder in a preview or form.
  """
  @spec dummy_type(User.t(), keyword()) :: Type.t()
  def dummy_type(user, attrs \\ []) do
    defaults = [name: "Workout", color: "#0e7490", template: "", template_fields: []]
    attrs = Keyword.merge(defaults, attrs)

    user
    |> Ecto.build_assoc(:workout_types, attrs)
    |> Type.derive_template_fields()
  end

  @spec user_workouts(User.t() | integer(), Date.t(), Date.t()) :: [Workout.t()]
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

  @spec get(integer()) :: Workout.t() | nil
  def get(id) do
    case Repo.one(from(w in Workout, where: w.id == ^id)) do
      nil -> nil
      w -> load_workout_fields(w)
    end
  end

  @spec changeset(Workout.t(), %{String.t() => any()} | %{atom() => any()}) :: Changeset.t()
  def changeset(workout, attrs \\ %{}), do: Workout.changeset(workout, attrs)

  @spec apply_changes(Changeset.t()) :: Workout.t()
  def apply_changes(changeset) do
    changeset
    |> Changeset.apply_changes()
    |> load_workout_fields()
  end

  @spec duplicate(Workout.t() | integer()) :: Workout.t()
  def duplicate(workout = %Workout{}), do: Workout.duplicate(workout)
  def duplicate(id), do: id |> get() |> Workout.duplicate()

  @spec create!(Workout.t(), %{String.t() => any()} | %{atom() => any()}) ::
          Workout.t() | no_return()
  def create!(wo \\ %Workout{}, attrs) do
    workout = wo |> Workout.changeset(attrs) |> Repo.insert!() |> load_workout_fields()
    maybe_broadcast({:ok, workout}, :workouts, :create)
    workout
  end

  @spec create(Workout.t(), %{String.t() => any()} | %{atom() => any()}) ::
          {:ok, Workout.t()} | {:error, Changeset.t()}
  def create(wo \\ %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.insert()
    |> maybe_load_workout_fields()
    |> maybe_broadcast(:workouts, :create)
  end

  @spec update(Workout.t() | integer(), %{String.t() => any()} | %{atom() => any()}) ::
          {:ok, Workout.t()} | {:error, Changeset.t()}
  def update(id, attrs) when is_integer(id), do: id |> get() |> update(attrs)

  def update(wo = %Workout{}, attrs) do
    wo
    |> Workout.changeset(attrs)
    |> Repo.update()
    |> maybe_load_workout_fields()
    |> maybe_broadcast(:workouts, :update)
  end

  @spec delete(Workout.t() | integer()) :: {:ok, Workout.t()} | {:error, Changeset.t()}
  def delete(id) when is_integer(id), do: id |> get() |> Repo.delete()

  def delete(workout = %Workout{}) do
    workout
    |> Repo.delete()
    |> maybe_broadcast(:workouts, :delete)
  end

  @doc """
  Create dummy workout.

  Create a dummy workout. Useful as a placeholder in a preview or form.
  """
  @spec dummy(User.t(), keyword()) :: Workout.t()
  def dummy(user, attrs \\ []) do
    attrs = Keyword.put_new_lazy(attrs, :type, fn -> dummy_type(user) end)

    user
    |> Ecto.build_assoc(:workouts, attrs)
    |> Workout.derive_description()
  end

  defp maybe_load_workout_fields({:ok, workout}), do: {:ok, load_workout_fields(workout)}
  defp maybe_load_workout_fields(t = {:error, _}), do: t

  defp load_workout_fields(workout = %Workout{user_id: user_id, type_id: type_id}) do
    Workout.derive_description(%{workout | type: type_by_id(user_id, type_id)})
  end

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
