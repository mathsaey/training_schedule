defmodule TrainingSchedule.Accounts.UserTest do
  use TrainingSchedule.DataCase, async: true
  alias TrainingSchedule.Accounts.User

  defp unset_password_field(user), do: %{user | password: nil}

  describe "authentication" do
    setup do
      {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
      [user: user]
    end

    test "with valid credentials", %{user: u} do
      {:ok, _} = User.authenticate(u.username, u.password)
    end

    test "does not store password", %{user: u} do
      {:ok, user} = User.authenticate(u.username, u.password)
      assert is_nil(user.password)
    end

    test "with invalid credentials", %{user: u} do
      :error = User.authenticate("testtest", u.password)
      :error = User.authenticate(u.username, "invalidpass")
    end
  end

  describe "user creation" do
    test "valid user" do
      {:ok, _} = User.create(%{username: "testuser", password: "testpassword"})
      User.create!(%{username: "otheruser", password: "otherpassword"})
    end

    test "with missing values" do
      {:error, cs} = User.create(%{password: "test"})
      assert "can't be blank" in errors_on(cs).username
      {:error, cs} = User.create(%{username: "test"})
      assert "can't be blank" in errors_on(cs).password

      assert_raise(Ecto.InvalidChangesetError, fn -> User.create!(%{password: "test"}) end)
      assert_raise(Ecto.InvalidChangesetError, fn -> User.create!(%{username: "test"}) end)
    end

    test "with invalid username" do
      {:error, cs} = User.create(%{username: "x"})
      assert "should be at least 3 character(s)" in errors_on(cs).username
      assert_raise(Ecto.InvalidChangesetError, fn -> User.create!(%{username: "x"}) end)

      name = "averyveryveryveryveryveryveryveryveryverylongusername"
      {:error, cs} = User.create(%{username: name})
      assert "should be at most 50 character(s)" in errors_on(cs).username
      assert_raise(Ecto.InvalidChangesetError, fn -> User.create!(%{username: name}) end)
    end

    test "with invalid password" do
      {:error, cs} = User.create(%{password: "x"})
      assert "should be at least 8 character(s)" in errors_on(cs).password
      assert_raise(Ecto.InvalidChangesetError, fn -> User.create!(%{password: "x"}) end)
    end

    test "duplicate username" do
      {:ok, _} = User.create(%{username: "testuser", password: "testpassword"})
      {:error, cs} = User.create(%{username: "testuser", password: "testpassword"})
      assert "has already been taken" in errors_on(cs).username

      assert_raise(Ecto.InvalidChangesetError, fn ->
        User.create!(%{username: "testuser", password: "testpassword"})
      end)
    end
  end

  test "user retrieval" do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    user = unset_password_field(user)
    assert user == User.get(user.id)
    assert user == User.get_by_name(user.username)
  end

  test "delete users" do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    user = unset_password_field(user)
    assert user == User.get(user.id)

    {:ok, user} = User.delete(user)
    assert is_nil(User.get(user.id))
  end

  test "delete users by id" do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    user = unset_password_field(user)
    assert user == User.get(user.id)

    {:ok, user} = User.delete(user.id)
    assert is_nil(User.get(user.id))
  end

  test "update username" do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    {:ok, _} = User.update(user, %{username: "anothername"})

    assert User.get(user.id).username == "anothername"
  end

  test "update username by id" do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    {:ok, _} = User.update(user, %{username: "anothername"})

    assert User.get(user.id).username == "anothername"
  end
end
