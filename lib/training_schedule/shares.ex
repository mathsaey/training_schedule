defmodule TrainingSchedule.Shares do
  import Ecto.Query
  alias TrainingSchedule.Repo
  alias TrainingSchedule.Shares.Share

  def create(share \\ %Share{}, attrs), do: share |> Share.changeset(attrs) |> Repo.insert()

  def get(uuid), do: Repo.one(from s in Share, where: s.id == ^uuid)
end
