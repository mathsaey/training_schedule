defmodule TrainingSchedule.Accounts.TokenTest do
  use TrainingSchedule.DataCase, async: true
  alias TrainingSchedule.Accounts.Token

  setup do
    [user: user_fixture()]
  end

  test "create token and authenticate", %{user: u} do
    token = Token.create(u.id)
    assert Token.to_user_id(token) == {:ok, u.id}
  end

  test "using an invalid token format", %{user: u} do
    <<_, _, token::binary>> = Token.create(u.id)
    assert Token.to_user_id(token) == :error
  end

  test "using an invalid challenge", %{user: u} do
    <<id::binary-size(16), _::binary-size(32)>> = Token.create(u.id)
    new_challenge = :crypto.strong_rand_bytes(32)
    assert Token.to_user_id(id <> new_challenge) == :error
  end
end
