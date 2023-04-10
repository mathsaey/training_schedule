defmodule TrainingScheduleWeb.Components.WorkoutComponents do
  use Phoenix.Component

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

  defp card_shared, do: "space-y-1p flex w-48 flex-col rounded p-4 m-2 text-center"
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
