defmodule TrainingSchedule.Repo.Migrations.AddWorkoutsCancelled do
  use Ecto.Migration

  def change do
    alter table("workouts") do
      add :cancelled?, :boolean, null: false, default: false
    end
  end
end
