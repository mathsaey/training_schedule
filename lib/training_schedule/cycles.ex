defmodule TrainingSchedule.Cycles do
  @moduledoc """
  Training cycles context.

  Training schedules are generally divided into "chunks" known as cycles. This is done on several
  levels:

  * A macro cycle is a period of training working towards a goal or several goals. A macro cycle
    could for instance constitute several weeks of training for a particular major race. Macro
    cycles may also represent an entire year of training.

  * A meso cycle represents a block of training with a specific goal. A meso cycle could, for
    instance, be several weeks of training that are focused on building endurance.

  * A micro cycle is the shortest training cycle, which typically lasts a week.

  This module contains features to reason over a list of workouts grouped as a training block.
  Currently, only support for microcycles is present.
  """
  alias __MODULE__.Micro
  alias TrainingSchedule.Workouts.Workout

  defmodule Micro do
    @moduledoc """
    The shortest possible training cycle.
    """

    @typedoc """
    Struct representing a micro cycle.

    The `:days` field is a list of `{date, list}` tuples, where `list` contains all the workouts
    schedule on the given `date`.

    The other fields contain statistics about the microcycle:

    * `:total_distance` contains the total distance of the cycle.
    * `:compare_prev` compares the micro cycle with the previous micro cycle. It is a map with
      two fields. If there is no previous micro cycle, this field is set to `nil`.
      * `:distance_diff`: The difference in distance between the previous cycle and this cycle.
      * `:distance_diff_pct`: Like `:distance_diff`, but expressed as a percentage. Absent when
        the previous cycle's distance is zero.
    """
    @type t :: %__MODULE__{
            days: [{Date.t(), [Workout.t()]}],
            total_distance: float(),
            compare_prev:
              %{
                required(:distance_diff) => float(),
                optional(:distance_diff_pct) => float()
              }
              | nil
          }

    defstruct [:days, :compare_prev, total_distance: 0]
  end

  @spec group_workouts([Workout.t()], Date.t(), Date.t(), integer()) :: [Micro.t()]
  def group_workouts(workouts, start, stop, length) do
    workouts = Enum.group_by(workouts, & &1.date)

    Date.range(start, stop, length)
    |> Enum.map(fn start ->
      start
      |> Date.range(Date.add(start, length - 1))
      |> Enum.map(&{&1, Map.get(workouts, &1, [])})
      |> then(&%Micro{days: &1, total_distance: total_distance(&1)})
    end)
    |> Enum.map_reduce(nil, fn
      micro, nil -> {micro, micro}
      micro, prev -> {%{micro | compare_prev: compare_prev(micro, prev)}, micro}
    end)
    |> elem(0)
  end

  defp total_distance(days) do
    days |> Enum.flat_map(&elem(&1, 1)) |> Enum.map(& &1.distance) |> Enum.sum()
  end

  defp compare_prev(%{total_distance: t}, %{total_distance: 0}), do: %{distance_diff: t}

  defp compare_prev(%{total_distance: micro}, %{total_distance: prev}) do
    diff = micro - prev
    %{distance_diff: diff, distance_diff_pct: 100 * (diff / prev)}
  end
end
