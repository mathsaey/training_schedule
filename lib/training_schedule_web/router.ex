defmodule TrainingScheduleWeb.Router do
  use TrainingScheduleWeb, :router
  import TrainingScheduleWeb.AuthController, only: [ensure_authenticated: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TrainingScheduleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TrainingScheduleWeb do
    pipe_through :browser

    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate
  end

  live_session :user, on_mount: TrainingScheduleWeb.AuthController do
    scope "/", TrainingScheduleWeb do
      pipe_through [:browser, :ensure_authenticated]

      live "/", ScheduleLive.Index, :index
      live "/from/:from/to/:to", ScheduleLive.Index, :index
      live "/from/:from/to/:to/new/:date", ScheduleLive.Index, :new
      live "/from/:from/to/:to/edit/:date/:id", ScheduleLive.Index, :edit

      live "/workouts", WorkoutTypeLive.Index, :index
      live "/workouts/new", WorkoutTypeLive.Index, :new
      live "/workouts/edit/:name", WorkoutTypeLive.Index, :edit

      get "/logout", AuthController, :logout
    end
  end
end
