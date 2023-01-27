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

## Ideas for future versions

- Share (parts of) your schedule publicly
- Integrate with strava, garmin connect, … to compare expected / actual mileage.
- Workout description / notes with markdown support
- Supplementary workouts (strength / stretches)
- Export calendar to (customisable) markdown for, e.g., writing race reports
- Create complete plans which can be added to the calendar with a single click
- Support for displaying additional information (e.g. focus of the current training block)

# Installation & Setup

## Using Docker

## Manual Setup

## Configuration

| Variable | Example | Default | Description |
| ----------- | ------- | ------- | ----------- |
| `TS_DB_PATH` | `"training_schedule.db"` | | The path to your database file. |
| `TS_SECRET_BASE_KEY` | `"Wc7eizeSdN7DQD9kpVkpnFPrbF8g43DAgJwdh5Ju9ZhVqw0XJjxta0JLh8xPDO9L"` | | A random value used for signing and encryption. Generate this using `mix phx.gen.secret`. |
| `TS_HOST` | `"training.example.com"` | | The url at which the site will be served. |
| `TS_IP` | `"127.0.0.1"` | `"0.0.0.0"` | The ip to which the webserver will bind. |
| `TS_PORT` | `"4000"` | `"4000"` | The port to which the webserver will listen. |

# Contributing

Issue reports, feature requests and contributions are always welcome. However,
do keep in mind that it may take some time for me to get back to you.
