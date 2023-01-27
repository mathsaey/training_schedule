defmodule TrainingSchedule.Accounts do
  alias __MODULE__.{User, UserToken}

  defdelegate get_user_by_id(id), to: User, as: :get
  defdelegate get_user_by_name(name), to: User, as: :get_by_name
  defdelegate create(attrs), to: User
  defdelegate create!(attrs), to: User

  def authenticate(username, password) do
    case User.authenticate(username, password) do
      {:ok, user} -> {:ok, UserToken.create(user.id)}
      :error -> :error
    end
  end

  defdelegate token_to_user_id(token), to: UserToken, as: :to_user_id
  defdelegate revoke_token(token), to: UserToken, as: :drop
end
