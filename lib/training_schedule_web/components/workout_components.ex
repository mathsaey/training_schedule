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

defmodule TrainingScheduleWeb.Components.WorkoutComponents do
  use Phoenix.Component
  use TrainingScheduleWeb, :html
  import TrainingScheduleWeb.CoreComponents

  embed_templates "workouts/*"

  attr :unit, :string, default: "km"
  attr :distance, :float, required: true
  attr :class, :string, default: nil

  def distance(assigns) do
    ~H"""
    <span class={["break-words font-light", @class]}>
      <%= format_distance(@distance) %> <%= @unit %>
    </span>
    """
  end

  defp format_distance(distance) when round(distance) == distance, do: round(distance)
  defp format_distance(distance), do: distance

  attr :id, :string, default: nil
  attr :action, :string, default: nil
  attr :distance, :float, default: nil
  attr :cancelled?, :boolean, default: false
  attr :type, TrainingSchedule.Workouts.Type, required: true
  attr :rest, :global, include: ~w(draggable replace)
  slot :inner_block, required: true

  def card(%{action: nil} = assigns) do
    ~H"""
    <div class={card_shared()} id={@id} style={"background-color:#{@type.color}"} {@rest}>
      <p class={card_title(assigns)}><%= @type.name %></p>
      <p :if={not @cancelled?} class={card_content(assigns)}><%= render_slot(@inner_block) %></p>
      <p :if={@distance}><.distance distance={@distance} class={card_distance(assigns)} /></p>
    </div>
    """
  end

  def card(assigns) do
    ~H"""
    <.link id={@id} patch={@action} {@rest}>
      <div class={[card_shared(), "hover:ring-4"]} style={"background-color:#{@type.color}"}>
        <p class={card_title(assigns)}><%= @type.name %></p>
        <p :if={not @cancelled?} class={card_content(assigns)}><%= render_slot(@inner_block) %></p>
        <p :if={@distance}><.distance distance={@distance} class={card_distance(assigns)} /></p>
      </div>
    </.link>
    """
  end

  defp card_shared do
    "space-y-1p flex w-64 lg:w-32 xl:w-40 flex-col rounded p-4 m-2 text-center"
  end

  defp card_title(%{cancelled?: true}), do: "break-words font-bold line-through decoration-2"
  defp card_title(_), do: "break-words font-bold"
  defp card_content(_), do: "break-words font-light"
  defp card_distance(%{cancelled?: true}), do: "line-through"
  defp card_distance(_), do: ""

  # TODO: Support for arbitrary amount of days, requires changes to tailwind grid template

  attr :cycles, :list, required: true
  attr :modify?, :boolean, default: false

  # defined in workouts/schedule.html.heex
  def schedule(assigns)

  defp schedule_cell_border, do: "border border-gray-200 dark:border-gray-600"

  defp schedule_cycle_days(_) do
    Date.range(Date.beginning_of_week(Date.utc_today()), Date.end_of_week(Date.utc_today()))
  end
end
