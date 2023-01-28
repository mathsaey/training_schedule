# TrainingSchedule.ex

Self-hosted training planner (for runners).

The goal of this project is to replace spreadsheets as a means to put together
your personal training plan. Currently, it enables the creation of custom
workout types which can be planned on a calendar.

This project is very much in its infancy. While the groundwork is present for
some upcoming features, limited time means they may not land any time soon.

It was also a nice excuse for me to learn css fundamentals by playing
with [tailwind](https://tailwindcss.com/), and to get used to developing web
applications with [Phoenix](https://www.phoenixframework.org/) and Phoenix
LiveView. Since it is my first time working with both of these technologies,
you should not expect to see idiomatic Tailwind or LiveView code here.

## Features

- Create custom workout types
- Plan workouts and display them on a calendar

Under development:

- Multi-account support (Done, with the exception of a UI to add users)

### Ideas for future versions

- Share (parts of) your schedule publicly
- Integrate with strava, garmin connect, … to compare expected / actual mileage.
- Workout description / notes with markdown support
- Supplementary workouts (strength / stretches)
- Export calendar to (customisable) markdown for, e.g., writing race reports
- Create complete plans which can be added to the calendar with a single click
- Support for displaying additional information (e.g. focus of the current training block)

## Getting Started

If you are not using Docker, you will need to install
[Elixir](https://elixir-lang.org/). Please refer to the
[official installation instructions](https://elixir-lang.org/install.html).

### Using docker-compose

- Copy the `docker-compose.example.yml` file in this repository and adjust it
  as needed.

- `$ git clone git@github.com:mathsaey/training_schedule.git`

- `$ docker-compose build`

- `$ docker-compose up`

- Once the container is up and running, you need to create an initial user:
  `$ docker-compose exec app ./bin/training_schedule rpc 'TrainingSchedule.Accounts.create!(%{username: "<your username>", password: "<your password>", admin?: true})'`

  Note that this command needs to be executed _while the container is running_.

  - If desired, additional users can be added in the same way. Ensure you only
    set `admin?` to `true` when you want the user to have admin rights in the
    future.

### Manual Setup

- [Install Elixir](https://elixir-lang.org/install.html).

- Fetch the application: `$ git clone git@github.com:mathsaey/training_schedule.git`

- Fetch the dependencies, build the static assets and compile a release:
  ```
  $ cd training_schedule
  $ MIX_ENV=prod mix deps.get
  $ MIX_ENV=prod mix deps.compile
  $ MIX_ENV=prod mix assets.deploy
  $ MIX_ENV=prod mix release
  ```

- A release folder will now be present in `_build/prod/rel/`. This folder
  contains a standalone version of the application, you may move it to the
  desired location.

- From the release folder, you can start the release with:
  `$ ./bin/entrypoint`.

  - The environment variables specified below must be set or the project will
    not start.

  - Instead of using `./bin/entrypoint` (which runs the database migrations and
    starts the server), you may run `./bin/migrate` once, after which
    `./bin/server` can be used to start the server.

- When the project is up and running, you need to create an initial user:
  `$ ./bin/training_schedule rpc 'TrainingSchedule.Accounts.create!(%{username: "<your username>", password: "<your password>", admin?: true})'`

  Note that this command needs to be executed _while the application is up and running_.

  - If desired, additional users can be added in the same way. Ensure you only
    set `admin?` to `true` when you want the user to have admin rights in the
    future.

### Development Setup

- [Install Elixir](https://elixir-lang.org/install.html).

- Fetch the application: `$ git clone git@github.com:mathsaey/training_schedule.git`

- Fetch and compile the dependencies:
  ```
  $ cd training_schedule
  $ mix deps.get
  $ mix deps.compile
  ```

- Set up the database: `$ mix ecto.setup`

- Start the server: `$ mix phx.server`. You can access it at
  `http://localhost:4000`. There is no need to set any environment variable in
  development.

## Configuration

The following environment variables can be used to configure the application.
Settings which do not have a default value must be specified when running in
production.

| Variable | Example | Default | Description |
| ----------- | ------- | ------- | ----------- |
| `TS_DB_PATH` | `"training_schedule.db"` | | The path to your database file. |
| `TS_SECRET_BASE_KEY` | `"Wc7eizeSdN7DQD9kpVkpnFPrbF8g43DAgJwdh5Ju9ZhVqw0XJjxta0JLh8xPDO9L"` | | A random value used for signing and encryption. Generate this using `mix phx.gen.secret` or . `opensssl rand -base64 48` |
| `TS_HOST` | `"training.example.com"` | | The url at which the site will be served. |
| `TS_IP` | `"127.0.0.1"` | `"0.0.0.0"` | The ip to which the webserver will bind. |
| `TS_PORT` | `"4000"` | `"4000"` | The port to which the webserver will listen. |

# Contributing

Issue reports, feature requests and contributions are always welcome. However,
do keep in mind that it may take some time for me to get back to you.
