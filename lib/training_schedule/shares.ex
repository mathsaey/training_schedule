defmodule TrainingSchedule.Shares do
  import Ecto.Query
  alias TrainingSchedule.Repo
  alias TrainingSchedule.Workouts
  alias TrainingSchedule.Shares.Share

  def create(share \\ %Share{}, attrs) do
    share
    |> Share.changeset(attrs)
    |> Repo.insert()
  end

  def get(uuid), do: Repo.one(from s in Share, where: s.id == ^uuid)

  def workouts_for(uuid) do
    share = get(uuid)
    Workouts.user_workouts(share.user_id, share.from, share.to)
  end
end
