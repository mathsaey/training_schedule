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
  attr :type, TrainingSchedule.Workouts.Type, required: true
  attr :rest, :global, include: ~w(draggable replace)
  slot :inner_block, required: true

  def card(%{action: nil} = assigns) do
    ~H"""
    <div class={card_shared()} id={@id} style={"background-color:#{@type.color}"} {@rest}>
      <p class={card_title()}><%= @type.name %></p>
      <p class={card_content()}><%= render_slot(@inner_block) %></p>
      <p :if={@distance}><.distance distance={@distance} /></p>
    </div>
    """
  end

  def card(assigns) do
    ~H"""
    <.link id={@id} patch={@action} {@rest}>
      <div class={[card_shared(), "hover:ring-4"]} style={"background-color:#{@type.color}"}>
        <p class="break-words font-bold"><%= @type.name %></p>
        <p class="break-words font-light"><%= render_slot(@inner_block) %></p>
        <p :if={@distance}><.distance distance={@distance} /></p>
      </div>
    </.link>
    """
  end

  defp card_shared do
    "space-y-1p flex w-64 lg:w-32 xl:w-40 flex-col rounded p-4 m-2 text-center"
  end

  defp card_title, do: "break-words font-bold"
  defp card_content, do: "break-words font-light"

  # TODO: highlight current week / day
  # TODO: Support for arbitrary amount of days, requires changes to tailwind grid template

  attr :cycles, :list, required: true
  attr :modify_fn, :any, default: nil

  # defined in workouts/schedule.html.heex
  def schedule(assigns)

  defp schedule_cell_border, do: "border border-gray-200 dark:border-gray-600"
  defp schedule_cycle_days(_), do: ~w(Mon Tue Wed Thu Fri Sat Sun)
end
