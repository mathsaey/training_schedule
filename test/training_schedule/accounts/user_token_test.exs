defmodule TrainingSchedule.Accounts.UserTokenTest do
  use TrainingSchedule.DataCase, async: true
  alias TrainingSchedule.Accounts.{User, UserToken}

  setup do
    {:ok, user} = User.create(%{username: "testuser", password: "testpassword"})
    [user: user]
  end

  test "create token and authenticate", %{user: u} do
    token = UserToken.create(u.id)
    assert UserToken.to_user_id(token) == {:ok, u.id}
  end

  test "using an invalid token format", %{user: u} do
    <<_, _, token::binary>> = UserToken.create(u.id)
    assert UserToken.to_user_id(token) == :error
  end

  test "using an invalid challenge", %{user: u} do
    <<id::binary-size(16), _::binary-size(32)>> = UserToken.create(u.id)
    new_challenge = :crypto.strong_rand_bytes(32)
    assert UserToken.to_user_id(id <> new_challenge) == :error
  end

  test "drop user tokens", %{user: u} do
    token = UserToken.create(u.id)
    assert UserToken.to_user_id(token) == {:ok, u.id}
    UserToken.drop_all(u.id)
    assert UserToken.to_user_id(token) == :error
  end

  test "multiple tokens", %{user: u} do
    token1 = UserToken.create(u.id)
    token2 = UserToken.create(u.id)
    token3 = UserToken.create(u.id)

    assert UserToken.to_user_id(token1) == {:ok, u.id}
    assert UserToken.to_user_id(token2) == {:ok, u.id}
    assert UserToken.to_user_id(token3) == {:ok, u.id}
  end
end
