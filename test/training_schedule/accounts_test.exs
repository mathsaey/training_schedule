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

defmodule TrainingSchedule.AccountsTest do
  use TrainingSchedule.DataCase, async: true

  alias TrainingSchedule.Accounts

  setup do
    [user: user_fixture()]
  end

  describe "user creation" do
    test "with create/1" do
      {:ok, _} = Accounts.create(%{username: "testuser2", password: "testpassword"})
    end

    test "with create!/1" do
      Accounts.create!(%{username: "testuser2", password: "testpassword"})
    end

    test "with missing values" do
      {:error, cs} = Accounts.create(%{password: "test"})
      assert "can't be blank" in errors_on(cs).username
      {:error, cs} = Accounts.create(%{username: "test"})
      assert "can't be blank" in errors_on(cs).password

      assert_raise(Ecto.InvalidChangesetError, fn -> Accounts.create!(%{password: "test"}) end)
      assert_raise(Ecto.InvalidChangesetError, fn -> Accounts.create!(%{username: "test"}) end)
    end

    test "with invalid username" do
      {:error, cs} = Accounts.create(%{username: "x"})
      assert "should be at least 3 character(s)" in errors_on(cs).username
      assert_raise(Ecto.InvalidChangesetError, fn -> Accounts.create!(%{username: "x"}) end)

      name = "averyveryveryveryveryveryveryveryveryverylongusername"
      {:error, cs} = Accounts.create(%{username: name})
      assert "should be at most 50 character(s)" in errors_on(cs).username
      assert_raise(Ecto.InvalidChangesetError, fn -> Accounts.create!(%{username: name}) end)
    end

    test "with invalid password" do
      {:error, cs} = Accounts.create(%{password: "x"})
      assert "should be at least 8 character(s)" in errors_on(cs).password
      assert_raise(Ecto.InvalidChangesetError, fn -> Accounts.create!(%{password: "x"}) end)
    end

    test "duplicate username", %{user: u} do
      {:error, cs} = Accounts.create(%{username: u.username, password: "testpassword"})
      assert "has already been taken" in errors_on(cs).username

      assert_raise(Ecto.InvalidChangesetError, fn ->
        Accounts.create!(%{username: u.username, password: "testpassword"})
      end)
    end
  end

  test "user retrieval", %{user: u} do
    # The password is not retrieved by database operations, so we unset it for comparisons
    u = %{u | password: nil}

    assert u == Accounts.by_id(u.id)
    assert u == Accounts.by_username(u.username)
  end

  describe "authentication" do
    test "with valid credentials", %{user: u} do
      {:ok, _} = Accounts.authenticate(u.username, u.password)
    end

    test "with invalid username", %{user: u} do
      :error = Accounts.authenticate("testtest", u.password)
    end

    test "with invalid password", %{user: u} do
      :error = Accounts.authenticate(u.username, "invalidpass")
    end
  end

  describe "tokens" do
    test "can be used to obtain user id", %{user: u} do
      {:ok, token} = Accounts.authenticate(u.username, u.password)
      {:ok, id} = Accounts.token_to_user_id(token)
      assert id == u.id
    end

    test "cannot be used after being revoked", %{user: u} do
      {:ok, token} = Accounts.authenticate(u.username, u.password)
      :ok = Accounts.revoke_token(token)
      :error = Accounts.token_to_user_id(token)
    end

    test "work when multiple tokens are created", %{user: u} do
      {:ok, token1} = Accounts.authenticate(u.username, u.password)
      {:ok, token2} = Accounts.authenticate(u.username, u.password)
      {:ok, token3} = Accounts.authenticate(u.username, u.password)

      assert Accounts.token_to_user_id(token1) == {:ok, u.id}
      assert Accounts.token_to_user_id(token2) == {:ok, u.id}
      assert Accounts.token_to_user_id(token3) == {:ok, u.id}
    end
  end
end
