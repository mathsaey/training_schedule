defmodule TrainingScheduleWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com), using the
  [heroicons_elixir](https://github.com/mveytsman/heroicons_elixir) project.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :unit, :string, default: "km"
  attr :distance, :float, required: true

  def distance(assigns) do
    ~H"""
    <%= format_distance(@distance) %> <%= @unit %>
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

  def workout_card(%{action: nil} = assigns) do
    ~H"""
    <div class={workout_card_shared()} id={@id} style={"background-color:#{@type.color}"} {@rest}>
      <p class={workout_card_title()}><%= @type.name %></p>
      <p class={workout_card_content()}><%= render_slot(@inner_block) %></p>
      <p :if={@distance} class={workout_card_distance()}>
        <.distance distance={@distance}/>
      </p>
    </div>
    """
  end

  def workout_card(assigns) do
    ~H"""
    <.link id={@id} patch={@action} {@rest}>
      <div class={[workout_card_shared(), "hover:ring-4"]} style={"background-color:#{@type.color}"}>
        <p class="break-words font-bold"><%= @type.name %></p>
        <p class="break-words font-light"><%= render_slot(@inner_block) %></p>
        <p :if={@distance} class={workout_card_distance()}>
          <.distance distance={@distance}/>
        </p>
      </div>
    </.link>
    """
  end

  defp workout_card_shared, do: "space-y-1p flex w-48 flex-col rounded p-4 m-2 text-center"
  defp workout_card_title, do: "break-words font-bold"
  defp workout_card_content, do: "break-words font-light"
  defp workout_card_distance, do: "break-words font-light"

  attr :id, :string, required: true
  attr :return, :string, required: true

  slot :preview, required: true
  slot :preview_action
  slot :inner_block, required: true

  def workout_form_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 m-auto flex h-full w-full flex-col rounded-lg bg-slate-200 shadow-lg dark:bg-slate-600 dark:outline-slate-700 lg:h-fit lg:w-fit"
      phx-key="escape"
      phx-remove={hide(@id)}
      phx-click-away={JS.dispatch("click", to: "#close_modal")}
      phx-window-keydown={JS.dispatch("click", to: "#close_modal")}
    >
      <div class="flex justify-end">
        <.link id="close_modal" replace patch={@return}>
          <Heroicons.x_mark mini class="m-2 h-5 w-5 stroke-slate-500 hover:stroke-slate-400" />
        </.link>
      </div>

      <div class="flex h-full flex-col px-8 pb-6 lg:flex-row">
        <div class="flex flex-col items-center justify-between pr-4">
          <%= render_slot(@preview) %>
          <%= render_slot(@preview_action) %>
        </div>
        <div class="px-4">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(navigate patch href replace method)
  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <.link class={[button_default_class(), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={[button_default_class(), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """

    # "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
    # "text-sm font-semibold leading-6 text-white active:text-white/80",
  end

  defp button_default_class do
    "inline-block bg-sky-500 text-slate-100 rounded-md py-2 px-4 mt-4 hover:ring-2"
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)
  attr :class, :string, default: nil
  attr :input_class, :string, default: nil

  slot :inner_block

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Phoenix.HTML.Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <label phx-feedback-for={@name} class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value="true"
        checked={@checked}
        class={["rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900", @class]}
        {@rest}
      />
      <%= @label %>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-4">
      <.label for={@id} phx-feedback-for={@name}><%= @label %></.label>
      <div class={input_border(@errors)}>
        <select
          id={@id || @name}
          name={@name}
          class={[
            input_border(@errors),
            "rounded w-full",
            "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
            "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
            @class
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt}><%= @prompt %></option>
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
      </div>
      <.error :for={msg <- @errors} phx-feedback-for={@name}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <.label for={@id} phx-feedback-for={@name}><%= @label %></.label>
    <textarea
      id={@id || @name}
      name={@name}
      class={[
        input_border(@errors),
        "mt-2 block min-h-[6rem] w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
        "text-zinc-900 focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5 sm:text-sm sm:leading-6",
        "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
        @class
      ]}
      {@rest}
    >

    <%= @value %></textarea>
    <.error :for={msg <- @errors} phx-feedback-for={@name}><%= msg %></.error>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} />
    """
  end

  def input(assigns) do
    ~H"""
    <div class="mb-4">
      <.label for={@id} phx-feedback-for={@name}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          input_border(@errors),
          "rounded",
          "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors} phx-feedback-for={@name}><%= msg %></.error>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5"

  defp input_border([_ | _] = _errors),
    do: "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

  @doc """
  Renders a label.
  """
  attr :rest, :global
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="mt-6" {@rest}>
      <p class="text-sm font-light dark:text-slate-100">
        <%= render_slot(@inner_block) %>
      </p>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr :rest, :global
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden" {@rest}>
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  def header(assigns) do
    ~H"""
    <header>
      <h1 class="mb-6 text-2xl"><%= render_slot(@inner_block) %></h1>
    </header>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <Heroicons.arrow_left solid class="inline h-3 w-3 stroke-current" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(TrainingScheduleWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(TrainingScheduleWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end
end
