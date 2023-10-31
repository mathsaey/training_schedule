# TrainingSchedule.ex
# Copyright (c) 2023, Mathijs Saey

# TrainingSchedule.ex is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# TrainingSchedule.ex is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

    live "/shares/:id", ShareLive.Show
  end

  live_session :user, on_mount: TrainingScheduleWeb.AuthController do
    scope "/", TrainingScheduleWeb do
      pipe_through [:browser, :ensure_authenticated]

      live "/", ScheduleLive.Index, :index
      live "/from/:from/to/:to", ScheduleLive.Index, :index
      live "/from/:from/to/:to/new/:date", ScheduleLive.Index, :new
      live "/from/:from/to/:to/edit/:date/:id", ScheduleLive.Index, :edit

      live "/types", WorkoutTypeLive.Index, :index
      live "/types/new", WorkoutTypeLive.Index, :new
      live "/types/edit/:name", WorkoutTypeLive.Index, :edit

      live "/shares", ShareLive.Manager, :index

      get "/logout", AuthController, :logout
    end
  end
end
