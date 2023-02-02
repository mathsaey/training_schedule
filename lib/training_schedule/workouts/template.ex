defmodule TrainingSchedule.Workouts.Template do
  import NimbleParsec

  @open ?{
  @close ?}

  not_a_brace = utf8_string([{:not, @open}, {:not, @close}], min: 1)
  close = ignore(ascii_char([@close]))
  open = ignore(ascii_char([@open]))

  wrapped_content =
    open
    |> concat(not_a_brace)
    |> concat(close)
    |> map({String, :trim, []})
    |> unwrap_and_tag(:field)

  other_content = not_a_brace

  defparsecp(:_parse, repeat(choice([wrapped_content, other_content])) |> eos(), inline: true)

  def parse(nil), do: {:ok, []}

  def parse(template) do
    case _parse(template) do
      {:ok, parsed, "", _, _, _} -> {:ok, parsed}
      {:error, _, rem, _, _, _} -> {:error, rem}
    end
  end

  def expand(template, values) do
    {:ok, parsed} = parse(template)

    Enum.map(parsed, fn
      {:field, name} -> values[name] || ""
      any -> any
    end)
  end

  def validate(field, template) do
    case parse(template) do
      {:ok, _} -> []
      {:error, rem} -> [{field, "Invalid template string: #{rem}"}]
    end
  end

  def get_fields(template) do
    case parse(template) do
      {:ok, parsed} ->
        {:ok,
         parsed
         |> Enum.filter(&match?({:field, _}, &1))
         |> Enum.map(&elem(&1, 1))
         |> Enum.uniq()}

      {:error, rem} ->
        {:error, rem}
    end
  end
end
