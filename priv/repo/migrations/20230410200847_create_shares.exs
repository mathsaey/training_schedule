defmodule TrainingSchedule.Repo.Migrations.CreateShares do
  use Ecto.Migration

  def change do
    create table("shares", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :from, :date, null: false
      add :to, :date, null: false

      add :user_id, references("users", on_delete: :delete_all)

      timestamps()
    end
  end
end
