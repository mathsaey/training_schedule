# TrainingSchedule.ex
# Copyright (c) 2023 - 2025, Mathijs Saey

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

defmodule TrainingScheduleWeb.ShareExportController do
  use TrainingScheduleWeb, :controller

  alias TrainingSchedule.{Shares, Workouts}
  alias TrainingSchedule.Shares.Share
  alias TrainingScheduleWeb.Endpoint

  def ics(conn, %{"id" => id}) do
    case Shares.get(id) do
      nil ->
        send_resp(conn, 404, "Share does not exist")

      share = %Share{user_id: user_id, from: from, to: to} ->
        ics = Workouts.user_workouts(user_id, from, to) |> to_ics(share)

        send_download(
          conn,
          {:binary, ics},
          charset: "utf-8",
          filename: id <> ".ics",
          content_type: "text/calendar"
        )
    end
  end

  defp to_ics(workouts, share) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(:basic)

    [
      "BEGIN:VCALENDAR\r\n",
      "VERSION:2.0\r\n",
      "CALSCALE:GREGORIAN\r\n",
      "PRODID:-//mathsaey//training_schedule ics export//EN\r\n",
      ["X-WR-CALNAME:", share.name, "\r\n"],
      workouts
      |> Enum.map(fn workout ->
        [
          "BEGIN:VEVENT\r\n",
          format_line("UID:#{Endpoint.host()}_#{workout.id}"),
          format_line("SUMMARY:#{workout.type.name} (#{format_distance(workout.distance)}km)"),
          format_line("DESCRIPTION:#{workout.description}"),
          ["DTSTART;VALUE=DATE:", Date.to_iso8601(workout.date, :basic), "\r\n"],
          ["DTSTAMP:", now, "\r\n"],
          "END:VEVENT\r\n"
        ]
      end),
      "END:VCALENDAR\r\n"
    ]
  end

  @ics_max_octets 75

  defp format_line(binary) when byte_size(binary) > @ics_max_octets do
    binary
    |> Stream.unfold(&String.next_grapheme_size/1)
    |> Enum.map(fn el -> el end)
    |> Stream.chunk_while(
      0,
      fn
        size, count when size + count > @ics_max_octets -> {:cont, count, size}
        size, count -> {:cont, size + count}
      end,
      fn size -> {:cont, size, 0} end
    )
    |> Enum.map(fn el -> el end)
    |> Stream.transform(0, fn size, start -> {[{start, size}], start + size} end)
    |> Enum.map(fn el -> el end)
    |> Stream.map(fn {start, size} -> binary_part(binary, start, size) end)
    |> Enum.join("\r\n ")
    |> then(&[&1, "\r\n"])
  end

  defp format_line(binary), do: [binary, "\r\n"]

  defp format_distance(distance) when round(distance) == distance, do: round(distance)
  defp format_distance(distance), do: distance
end
