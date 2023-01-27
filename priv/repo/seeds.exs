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
