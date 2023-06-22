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

defmodule TrainingSchedule.WorkoutsTest do
  use TrainingSchedule.DataCase, async: true

  alias Phoenix.PubSub
  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Workouts.{Type, Workout}

  setup do
    [user: user_fixture()]
  end

  describe "create_type(!)/1" do
    setup %{user: user} do
      [
        attributes: %{
          name: "Workout",
          color: "#000000",
          user_id: user.id,
          template: "{ times }x100m"
        }
      ]
    end

    test "smoke test", %{attributes: attrs} do
      {:ok, _} = Workouts.create_type(%Type{}, attrs)
      %Type{} = Workouts.create_type!(%Type{}, %{attrs | name: "Another name"})
    end

    test "correctly extracts template_fields", %{attributes: attrs} do
      {:ok, type} = Workouts.create_type(%Type{}, attrs)
      assert type.template_fields == ["times"]
    end

    test "with missing values", %{attributes: attrs} do
      {:error, cs} = Workouts.create_type(%Type{}, Map.delete(attrs, :name))
      assert "can't be blank" in errors_on(cs).name
      {:error, cs} = Workouts.create_type(%Type{}, Map.delete(attrs, :color))
      assert "can't be blank" in errors_on(cs).color
      {:error, cs} = Workouts.create_type(%Type{}, Map.delete(attrs, :user_id))
      assert "can't be blank" in errors_on(cs).user_id

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, Map.delete(attrs, :name))
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, Map.delete(attrs, :color))
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, Map.delete(attrs, :user_id))
      end)
    end

    test "with invalid names", %{attributes: attrs} do
      {:error, cs} = Workouts.create_type(%Type{}, %{attrs | name: "x"})
      assert "should be at least 2 character(s)" in errors_on(cs).name

      longname = "x" |> List.duplicate(61) |> Enum.join("")
      {:error, cs} = Workouts.create_type(%Type{}, %{attrs | name: longname})
      assert "should be at most 60 character(s)" in errors_on(cs).name

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, %{attrs | name: "x"})
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, %{attrs | name: longname})
      end)
    end

    test "with overly long templates", %{attributes: attrs} do
      longtemplate = "x" |> List.duplicate(141) |> Enum.join("")
      {:error, cs} = Workouts.create_type(%Type{}, %{attrs | template: longtemplate})
      assert "should be at most 140 character(s)" in errors_on(cs).template

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, %{attrs | template: longtemplate})
      end)
    end

    test "with invalid template format", %{attributes: attrs} do
      {:error, cs} = Workouts.create_type(%Type{}, %{attrs | template: "test { notclosed"})
      assert "invalid template string: { notclosed" in errors_on(cs).template

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, %{attrs | template: "{ notclosed"})
      end)
    end

    test "with invalid color format", %{attributes: attrs} do
      {:error, cs} = Workouts.create_type(%Type{}, %{attrs | color: "x"})
      assert "has invalid format" in errors_on(cs).color

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create_type!(%Type{}, %{attrs | color: "x"})
      end)
    end

    test "with duplicate names", %{attributes: attrs} do
      {:ok, _} = Workouts.create_type(attrs)

      {:error, cs} = Workouts.create_type(%Type{}, attrs)
      assert "has already been taken" in errors_on(cs).name

      assert_raise(Ecto.InvalidChangesetError, fn -> Workouts.create_type!(%Type{}, attrs) end)
    end

    test "allows duplicate names from different users", %{attributes: attrs} do
      alt_user = user_fixture(%{username: "testuser2"})
      {:ok, _} = Workouts.create_type(attrs)
      {:ok, _} = Workouts.create_type(%{attrs | user_id: alt_user.id})
    end

    test "publishes message", %{user: user, attributes: attrs} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.create_type!(attrs) end)
      assert_receive {:types, :create, _type}
    end
  end

  describe "workout type" do
    setup %{user: user} do
      attrs = %{color: "#000000", user_id: user.id, template: "{reps}"}
      {:ok, t1} = Workouts.create_type(Map.merge(attrs, %{name: "type1"}))
      {:ok, t2} = Workouts.create_type(Map.merge(attrs, %{name: "type2"}))
      [type1: t1, type2: t2]
    end

    test "retrieval when the workout does not exist", %{user: user} do
      assert Workouts.type_by_id(user, -1) == nil
      assert Workouts.type_by_name(user, "does not exist") == nil
    end

    test "retrieval", %{user: user, type1: t1, type2: t2} do
      ids = user |> Workouts.user_types() |> Enum.map(& &1.id)
      assert ids == [t1.id, t2.id]

      assert Workouts.type_by_id(user.id, t1.id).id == t1.id
      assert Workouts.type_by_name(user.id, t2.name).id == t2.id
    end

    test "retrieval sets template", %{user: user, type1: t1, type2: t2} do
      user
      |> Workouts.user_types()
      |> Enum.all?(&(&1.template_fields == ["reps"]))
      |> assert()

      assert Workouts.type_by_id(user, t1.id).template_fields == ["reps"]
      assert Workouts.type_by_id(user, t2.id).template_fields == ["reps"]

      assert Workouts.type_by_name(user.id, t1.name).template_fields == ["reps"]
      assert Workouts.type_by_name(user.id, t2.name).template_fields == ["reps"]
    end

    test "updates", %{user: user, type1: t1, type2: t2} do
      {:ok, t1} = Workouts.update_type(t1, %{name: "new name"})
      {:ok, t2} = Workouts.update_type(t2, %{template: "new template"})

      assert Workouts.type_by_id(user.id, t1.id).name == "new name"
      assert Workouts.type_by_id(user.id, t2.id).template_fields == []
    end

    test "updates publish message", %{user: user, type1: type} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.update_type(type, %{name: "new name"}) end)
      assert_receive {:types, :update, _type}
    end

    test "deletion", %{user: user, type1: t} do
      assert Workouts.type_by_id(user.id, t.id).id == t.id

      {:ok, t} = Workouts.delete_type(t)

      assert Workouts.type_by_id(user.id, t.id) == nil
    end

    test "deletion publishes message", %{user: user, type1: type} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.delete_type(type) end)
      assert_receive {:types, :delete, _type}
    end
  end

  describe "create/2" do
    setup %{user: user} do
      type = type_fixture(user, %{template: "{reps}x{distance}"})

      attrs = %{
        user_id: user.id,
        type_id: type.id,
        date: Date.utc_today(),
        distance: 5.0,
        description_fields: %{"reps" => "5", "distance" => "400m"}
      }

      [type: type, attributes: attrs]
    end

    test "smoke test", %{attributes: attrs} do
      {:ok, _} = Workouts.create(attrs)
      %Workout{} = Workouts.create!(attrs)
    end

    test "correctly creates description", %{attributes: attrs} do
      {:ok, workout} = Workouts.create(attrs)
      assert workout.description == ["5", "x", "400m"]
    end

    test "with missing values", %{attributes: attrs} do
      {:error, cs} = Workouts.create(Map.delete(attrs, :date))
      assert "can't be blank" in errors_on(cs).date

      {:error, cs} = Workouts.create(Map.delete(attrs, :distance))
      assert "can't be blank" in errors_on(cs).distance

      {:error, cs} = Workouts.create(Map.delete(attrs, :user_id))
      assert "can't be blank" in errors_on(cs).user_id

      {:error, cs} = Workouts.create(Map.delete(attrs, :type_id))
      assert "can't be blank" in errors_on(cs).type_id

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create!(Map.delete(attrs, :date))
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create!(Map.delete(attrs, :distance))
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create!(Map.delete(attrs, :user_id))
      end)

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Workouts.create!(Map.delete(attrs, :type_id))
      end)
    end

    test "publishes message", %{user: user, attributes: attrs} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.create(attrs) end)
      assert_receive {:workouts, :create, _workout}
    end
  end

  describe "workouts" do
    setup %{user: user} do
      type = type_fixture(user, %{template: "{reps}x{distance}"})

      attrs = %{
        user_id: user.id,
        type_id: type.id,
        date: Date.utc_today(),
        distance: 5.0,
        description_fields: %{"reps" => "5", "distance" => "400m"}
      }

      workout = Workouts.create!(attrs)

      [type: type, workout: workout, attributes: attrs]
    end

    test "retrieval with user_workouts", %{user: user, attributes: attrs, workout: workout} do
      wo1 = Workouts.create!(attrs)
      wo2 = Workouts.create!(attrs)

      workout_ids =
        user
        |> Workouts.user_workouts(Date.utc_today(), Date.utc_today())
        |> Enum.map(& &1.id)

      assert workout.id in workout_ids
      assert wo1.id in workout_ids
      assert wo2.id in workout_ids

      workout_ids =
        user.id
        |> Workouts.user_workouts(~D[1991-12-08], ~D[1991-12-09])
        |> Enum.map(& &1.id)

      assert workout.id not in workout_ids
      assert wo1.id not in workout_ids
      assert wo2.id not in workout_ids
    end

    test "specific retrieval", %{workout: workout} do
      assert Workouts.get(workout.id).id == workout.id
    end

    test "specific retrieval loads description", %{workout: workout} do
      assert Workouts.get(workout.id).description == ["5", "x", "400m"]
    end

    test "specific retrieval returns nil when id does not exist" do
      assert Workouts.get(-1) == nil
    end

    test "update", %{workout: workout} do
      {:ok, workout} = Workouts.update(workout, %{distance: 6.0})
      assert Workouts.get(workout.id).distance == 6.0
    end

    test "update with id", %{workout: workout} do
      {:ok, workout} = Workouts.update(workout.id, %{distance: 6.0})
      assert Workouts.get(workout.id).distance == 6.0
    end

    test "update updates description", %{user: user, workout: workout} do
      new_type = type_fixture(user, %{name: "different", template: "{field}"})

      {:ok, workout} = Workouts.update(workout, %{type_id: new_type.id})
      assert workout.description == [""]

      {:ok, workout} = Workouts.update(workout, %{description_fields: %{"field" => "test"}})
      assert workout.description == ["test"]
    end

    test "update publishes message", %{user: user, workout: workout} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.update(workout, %{distance: 6.0}) end)
      assert_receive {:workouts, :update, recv_workout}
      assert recv_workout.id == workout.id
    end

    test "deletion", %{workout: workout} do
      {:ok, workout} = Workouts.delete(workout)
      assert Workouts.get(workout.id) == nil
    end

    test "deletion by id", %{workout: workout} do
      {:ok, workout} = Workouts.delete(workout.id)
      assert Workouts.get(workout.id) == nil
    end

    test "deletion publishes message", %{user: user, workout: workout} do
      PubSub.subscribe(TrainingSchedule.PubSub, "workouts:#{user.id}")
      spawn_sandboxed(fn -> Workouts.delete(workout) end)
      assert_receive {:workouts, :delete, recv_workout}
      assert recv_workout.id == workout.id
    end

    test "duplication", %{user: user, workout: workout} do
      dup = %Workout{} = Workouts.duplicate(workout)
      assert dup.id == nil
      assert dup.user_id == user.id
      assert dup.type_id == workout.type.id
    end

    test "duplication by id", %{user: user, workout: workout} do
      dup = %Workout{} = Workouts.duplicate(workout.id)
      assert dup.id == nil
      assert dup.user_id == user.id
      assert dup.type_id == workout.type.id
    end
  end
end
