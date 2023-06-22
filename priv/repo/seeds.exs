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

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TrainingSchedule.Repo.insert!(%TrainingSchedule.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Temporary until we support "real" accounts. For now all data is attached to the root account.
root_user =
  TrainingSchedule.Accounts.create!(%{
    username: "root",
    password: "rootpassword",
    admin?: true
  })

# This should be handled on new user creation later
TrainingSchedule.Workouts.create_type!(%{
  name: "Race",
  user_id: root_user.id,
  template: "{race name}",
  color: "#DC2626"
})
