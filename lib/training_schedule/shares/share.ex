defmodule TrainingSchedule.Shares.Share do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "shares" do
    field :from, :date
    field :to, :date

    belongs_to :user, TrainingSchedule.Accounts.User

    timestamps()
  end

  def changeset(share, attrs) do
    share
    |> cast(attrs, [:from, :to, :user_id])
    |> validate_required([:from, :to, :user_id])
    |> assoc_constraint(:user)
  end
end
