defmodule TrainingSchedule.WorkoutsTest do
  use TrainingSchedule.DataCase, async: true

  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Workouts.{Type, Workout}

  setup do
    [user: user_fixture(), alt_user: user_fixture(%{username: "testuser2"})]
  end

  describe "create_type(!)/1" do
    setup %{user: user} do
      [attributes: %{
        name: "Workout",
        color: "#000000",
        user_id: user.id,
        template: "{ times }x100m",
      }]
    end

    test "smoke test", %{attributes: attrs} do
      {:ok, _} = Workouts.create_type(%Type{}, attrs)
    end

    test "smoke test!", %{attributes: attrs} do
      # Test this separately to avoid issues with duplicate names
      Workouts.create_type!(%Type{}, attrs)
    end

    test "correctly extracts template_fields", %{attributes: attrs} do
      {:ok, workout} = Workouts.create_type(%Type{}, attrs)
      assert workout.template_fields == ["times"]
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

    test "with duplicate names", %{attributes: attrs, alt_user: alt_user} do
      {:ok, _} = Workouts.create_type!(attrs)

      {:error, cs} = Workouts.create_type(%Type{}, attrs)
      assert "has already been taken" in errors_on(cs).name

      assert_raise(Ecto.InvalidChangesetError, fn -> Workouts.create_type!(%Type{}, attrs) end)

      {:ok, _} = Workouts.create_type(%{attrs | user_id: alt_user.id})
    end
  end

  describe "workout types" do
    setup %{user: user} do
      attrs = %{color: "#000000", user_id: user.id, template: "{reps}"}
      {:ok, t1} = Workouts.create_type!(Map.merge(attrs, %{name: "type1"}))
      {:ok, t2} = Workouts.create_type!(Map.merge(attrs, %{name: "type2"}))
      [type1: t1, type2: t2]
    end

    test "retrieval", %{user: user, type1: t1, type2: t2} do
      ids = user |> Workouts.user_types() |> Enum.map(&(&1.id))
      assert t1.id in ids
      assert t2.id in ids

      ids = user.id |> Workouts.user_types() |> Enum.map(&(&1.id))
      assert t1.id in ids
      assert t2.id in ids

      assert Workouts.type_by_id(t1.id).id == t1.id
      assert Workouts.type_by_id(t2.id).id == t2.id

      assert Workouts.type_by_name(user.id, t1.name).id == t1.id
      assert Workouts.type_by_name(user.id, t2.name).id == t2.id
    end

    test "retrieval sets template", %{user: user, type1: t1, type2: t2} do
      user
      |> Workouts.user_types()
      |> Enum.all?(&(&1.template_fields == ["reps"]))
      |> assert()

      assert Workouts.type_by_id(t1.id).template_fields == ["reps"]
      assert Workouts.type_by_id(t2.id).template_fields == ["reps"]

      assert Workouts.type_by_name(user.id, t1.name).template_fields == ["reps"]
      assert Workouts.type_by_name(user.id, t2.name).template_fields == ["reps"]
    end
  end
end
