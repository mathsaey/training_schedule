defmodule TrainingSchedule.Workouts.Template do
  import NimbleParsec

  @open ?{
  @close ?}

  not_a_brace = utf8_char([{:not, @open}, {:not, @close}])
  opening_brace = ascii_char([@open])
  closing_brace = ascii_char([@close])

  wrapped_content =
    ignore(opening_brace)
    |> times(not_a_brace, min: 1)
    |> ignore(closing_brace)
    |> reduce({Kernel, :to_string, []})
    |> unwrap_and_tag(:field)

  other_content = times(not_a_brace, min: 1) |> reduce({Kernel, :to_string, []})

  defparsecp(:_parse, repeat(choice([wrapped_content, other_content])) |> eos(), inline: true)

  def parse(template) do
    case _parse(template) do
      {:ok, parsed, "", _, _, _} ->
        {:ok,
         Enum.map(parsed, fn
           {:field, str} -> {:field, String.trim(str)}
           any -> any
         end)}

      {:error, _, rem, _, _, _} ->
        {:error, rem}
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
