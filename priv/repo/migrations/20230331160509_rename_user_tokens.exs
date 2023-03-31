defmodule TrainingSchedule.Repo.Migrations.RenameUserTokens do
  use Ecto.Migration

  def change do
    rename table("user_tokens"), to: table("tokens")
  end
end
