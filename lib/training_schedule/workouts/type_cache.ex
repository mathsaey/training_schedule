defmodule TrainingSchedule.Workouts.TypeCache do
  @moduledoc """
  Type Cache server.

  This module implements a GenServer which maintains an ets table. This table maintains a cache of
  all workout types associated with a user. This is done to avoid repetitively querying the
  database for workout types, which tend not to change often.
  """
  use GenServer
  import Ecto.Query

  alias TrainingSchedule.Repo
  alias TrainingSchedule.Workouts.Type

  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
  Invalidate the cache entries associated with `user_id`.

  All entries of the user present in the cache are purged, after which they are reloaded. This is
  done under the assumption data for "active" users will be fetched soon after editing.

  This operation always needs to synchronise with the cache server, which queries the database to
  reload the types for the provided `user_id`.
  """
  @spec invalidate(integer()) :: :ok
  def invalidate(user_id), do: GenServer.call(__MODULE__, {:reload, user_id})

  @doc """
  Fetch all the types associated with `user_id`.

  Attempt to fetch the types for a user from the cache, load them into the cache from the database
  and fetch them afterwards if they are currently not loaded.

  If no records for the user are present in the database, this operation synchronises with the
  cache server, which will query the database. This is done under the assumption users with no
  existing types are a rare occurrence.
  """
  @spec fetch_user_types(integer()) :: [Type.t()]
  def fetch_user_types(user_id), do: select_load_if_empty(user_id, %{})

  @doc """
  Fetch the type with `id` associated with `user_id`.

  Attempt to fetch the type with `id` from the cache. If no entry is present, the operation
  synchronises with the cache server, which will query the database. This is done under the
  assumption a cache miss occurs because the type is not loaded yet. Said otherwise, this
  operation assumes that queries to non-existent ids are infrequent.
  """
  @spec fetch_type_by_id(integer(), integer()) :: Type.t() | nil
  def fetch_type_by_id(user_id, id) do
    case select_load_if_empty(user_id, %{id: id}) do
      [] -> nil
      [type] -> type
    end
  end

  @doc """
  Fetch the type with name `name` associated with `user_id`.

  Attempt to fetch the type with name `name` from the cache. If no entry is present, the operation
  synchronises with the cache server, which will query the database. This is done under the
  assumption a cache miss occurs because the type is not loaded yet. Said otherwise, this
  operation assumes that queries to non-existent names are infrequent.
  """
  @spec fetch_type_by_name(integer(), String.t()) :: Type.t() | nil
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
