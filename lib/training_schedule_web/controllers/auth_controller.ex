defmodule TrainingScheduleWeb.AuthController do
  use TrainingScheduleWeb, :controller
  import Phoenix.Component, only: [assign_new: 3]
  require Logger

  alias Phoenix.LiveView.Socket
  alias TrainingSchedule.Accounts
  alias TrainingScheduleWeb.Endpoint

  defp login_path(params \\ %{}), do: ~p"/login?#{params}"
  defp home_path(), do: ~p"/"

  def login(conn, _) do
    if valid_token?(conn) do
      conn
      |> put_flash(:error, "You are already logged in")
      |> redirect(to: home_path())
    else
      render(conn, "login.html", navigate: conn.query_params["navigate"])
    end
  end

  def authenticate(conn, %{"login" => %{"username" => u, "password" => p, "navigate" => n}}) do
    case Accounts.authenticate(u, p) do
      {:ok, token} ->
        Logger.info("New session for user #{u}")

        conn
        |> configure_session(renew: true)
        |> clear_session()
        |> put_session(:session_token, token)
        |> put_session(:live_socket_id, "users_socket:#{Base.url_encode64(token)}")
        |> redirect(to: if(n == "", do: home_path(), else: n))

      :error ->
        Logger.info("Failed login attempt for user #{u}")

        conn
        |> put_flash(:error, "Invalid username or password")
        |> render("login.html", navigate: n)
    end
  end

  def logout(conn, _) do
    conn |> get_session(:session_token) |> Accounts.revoke_token()
    conn |> get_session(:live_socket_id) |> Endpoint.broadcast("disconnect", %{})
    conn |> configure_session(renew: true) |> clear_session() |> redirect(to: login_path())
  end

  def ensure_authenticated(conn, _) do
    with token when not is_nil(token) <- get_session(conn, :session_token),
         {:ok, id} <- Accounts.token_to_user_id(token) do
      conn
      |> assign(:session_token, token)
      |> assign(:user_id, id)
    else
      _ ->
        conn
        |> put_flash(:error, "You need to be logged in to access that page")
        |> redirect_to_login()
        |> halt()
    end
  end

  def on_mount(:default, _params, %{"session_token" => token}, socket) do
    socket
    |> assign_new(:session_token, fn -> token end)
    |> assign_new(:user_id, fn %{session_token: t} ->
      case Accounts.token_to_user_id(t) do
        {:ok, id} -> id
        _ -> :error
      end
    end)
    |> assign_new(:user, fn
      %{user_id: :error} -> :error
      %{user_id: id} -> Accounts.by_id(id)
    end)
    |> case do
      %Socket{assigns: %{user: :error}} -> {:halt, redirect(socket, to: login_path())}
      socket = %Socket{assigns: %{user: _}} -> {:cont, socket}
    end
  end

  def on_mount(:default, _params, _, socket), do: {:halt, redirect(socket, to: login_path())}

  def logged_in_token?(conn), do: not is_nil(get_session(conn, :session_token))

  @doc """
  Verify if the user has a valid logged in token.

  This function works similar to `logged_in_token?` but actually verifies if the token is valid by
  checking the database.
  """
  def valid_token?(conn) do
    token = get_session(conn, :session_token)

    case token && Accounts.token_to_user_id(token) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp redirect_to_login(%{method: "GET"} = conn) do
    redirect(conn, to: login_path(%{navigate: current_path(conn)}))
  end

  defp redirect_to_login(conn), do: redirect(conn, to: login_path())
end
