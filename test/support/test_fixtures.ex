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
    attrs =
      %{
        name: "Workout",
        color: "#0e7490",
        template: "{times}x100m",
        template_fields: ["times"]
      }
      |> Map.merge(attrs)

    Ecto.build_assoc(user, :workout_types, attrs)
  end
end
