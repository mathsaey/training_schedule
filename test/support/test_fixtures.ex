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

defmodule TrainingSchedule.TestFixtures do
  @moduledoc """
  Shared test fixtures.

  This module defines several fixtures that can be used in tests. This module is imported when
  `use`ing the `TrainingSchedule.DataCase` module.
  """

  def user_fixture(attrs \\ %{}) do
    %{
      username: "test_fixture_user",
      password: "test_fixture_password",
      admin?: false
    }
    |> Map.merge(attrs)
    |> TrainingSchedule.Accounts.create!()
  end

  def type_fixture(user \\ user_fixture(), attrs \\ %{}) do
    %{
      user_id: user.id,
      user: user,
      name: "Workout",
      color: "#0e7490",
      template: "{times}x100m",
      template_fields: ["times"]
    }
    |> Map.merge(attrs)
    |> TrainingSchedule.Workouts.create_type!()
  end
end
