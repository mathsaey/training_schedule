defmodule TrainingSchedule.Workouts.TypeCache do
  @moduledoc """
  Type Cache server.

  This module implements a GenServer which maintains an ets table. This table maintains a cache of
  all workout types associated with a user. This is done to avoid repetitively querying the
  database for workout types, which tend not to change often.

  ## Edge cases & Assumptions

  When data is fetched from an ets table, we cannot distinguish between the case where there are
  no types for a user and between the case where the types for a user where not cached yet. We
  therefore always load the types of a user in the cache when we encounter a cache miss. This is
  done for the following reasons:

  * Users without workout types should be a rare occurrence. Moreover, fetching a type by name or
  id should be done with a valid name or id most of the time. Therefore, an empty return list
  will correspond to a cache miss most of the time.

  * Cache misses should be relatively infrequent (they should only occur once, when we fetch the
  types of a user for the first time), we therefore write our code for the common case.

  * The alternative, where a dummy value is stored in the cache for users without workout types,
  could cause memory leaks if an attacker manages to query the cache for non-existent user ids.

  Finally, we reload the types of a user when they are updated in any way. This is done under the
  assumption that types will be loaded soon after they are updated.
  """
  use GenServer
  import Ecto.Query

  alias TrainingSchedule.Repo
  alias TrainingSchedule.Workouts.Type

  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def invalidate(user_id), do: GenServer.call(__MODULE__, {:reload, user_id})

  def fetch_user_types(user_id), do: select_load_if_empty(user_id, %{})

  def fetch_type_by_id(user_id, id) do
    case select_load_if_empty(user_id, %{id: id}) do
      [] -> nil
      [type] -> type
    end
  end

  def fetch_type_by_name(user_id, name) do
    case select_load_if_empty(user_id, %{name: name}) do
      [] -> nil
      [type] -> type
    end
  end

  defp select_load_if_empty(user_id, match_map) do
    match_spec = [{{user_id, match_map}, [], [{:element, 2, :"$_"}]}]

    case :ets.select(__MODULE__, match_spec) do
      [] ->
        GenServer.call(__MODULE__, {:reload, user_id})
        :ets.select(__MODULE__, match_spec)

      lst ->
        lst
    end
  end

  @impl true
  def init([]) do
    :ets.new(__MODULE__, [:named_table, :bag, read_concurrency: true])
    {:ok, nil}
  end

  @impl true
  def handle_call({:reload, user_id}, _from, nil) do
    :ets.delete(__MODULE__, user_id)

    from(t in Type, where: t.user_id == ^user_id, order_by: t.name)
    |> Repo.all()
    |> Enum.map(&{user_id, Type.derive_template_fields(&1)})
    |> then(&:ets.insert(__MODULE__, &1))

    {:reply, :ok, nil}
  end
end
