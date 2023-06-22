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

import Config

# Only activates phoenix when the PHX_SERVER env variable is set. This is automatically done by
# the bin/server script generated as part of a release.
if System.get_env("PHX_SERVER") do
  config :training_schedule, TrainingScheduleWeb.Endpoint, server: true
end

# Fetch the following values from environment variables. This is only done for production builds.
# Defaults for other builds are set in `config/dev.exs` and `config/test.exs`.
if config_env() == :prod do
  database_path =
    System.get_env("TS_DB_PATH") ||
      raise """
      environment variable TS_DB_PATH is missing.
      For example: /var/lib/training_schedule/training_schedule.db
      """

  secret_key_base =
    System.get_env("TS_SECRET_BASE_KEY") ||
      raise """
      environment variable TS_SECRET_BASE_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("TS_HOST") ||
      raise """
      environment variable TS_HOST is missing.
      For example: training.example.com
      """

  {:ok, ip} = :inet.parse_address(String.to_charlist(System.get_env("TS_IP") || "0.0.0.0"))
  port = String.to_integer(System.get_env("TS_PORT") || "4000")

  config :training_schedule, TrainingSchedule.Repo, database: database_path

  config :training_schedule, TrainingScheduleWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: ip, port: port],
    secret_key_base: secret_key_base
end
