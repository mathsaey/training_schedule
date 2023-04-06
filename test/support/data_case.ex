defmodule TrainingSchedule.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TrainingSchedule.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  alias TrainingSchedule.Repo

  using do
    quote do
      alias TrainingSchedule.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import TrainingSchedule.DataCase
      import TrainingSchedule.TestFixtures
    end
  end

  setup tags do
    TrainingSchedule.DataCase.setup_sandbox(tags)
    TrainingSchedule.DataCase.setup_type_cache(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  Ensure the type cache can access the database and reset it.

  Note that the type cache ets table may contain data from previous test runs. However, since
  every created user has a separate user_id, this should not affect the test results.
  """
  def setup_type_cache(_) do
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), TrainingSchedule.Workouts.TypeCache)
  end

  @doc """
  Spawn a function which has access to the sandbox.
  """
  def spawn_sandboxed(fun) do
    pid = spawn(fn -> receive(do: (:start -> fun.())) end)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)
    send(pid, :start)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
