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
