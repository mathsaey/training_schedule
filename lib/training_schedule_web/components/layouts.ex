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

defmodule TrainingScheduleWeb.Layouts do
  use TrainingScheduleWeb, :html
  alias TrainingScheduleWeb.AuthController

  @version Mix.Project.config()[:version]

  defp logged_in_links do
    [
      {"Workout Types", ~p"/types"},
      {"Log out", ~p"/logout"}
    ]
  end

  defp logged_out_links do
    [
      {"Log in", ~p"/login"}
    ]
  end

  defp version, do: @version

  defp footer_links do
    [
      {"Source Code", URI.parse("https://github.com/mathsaey/training_schedule")}
    ]
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "flex justify-between items-center w-5/6 sm:w-1/2 p-2 text-center rounded-md",
        @kind == :info && "bg-cyan-500 text-cyan-800",
        @kind == :error && "bg-red-500 text-red-900"
      ]}
      {@rest}
    >
      <Heroicons.information_circle :if={@kind == :info} mini class="h-5 w-5" />
      <Heroicons.exclamation_circle :if={@kind == :error} solid class="h-5 w-5" />
      <%= msg %>
      <button :if={@close} type="button" class="group p-2" aria-label="close">
        <Heroicons.x_mark solid class="h-5 w-5 stroke-current opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  embed_templates "layouts/*"
end
