defmodule TrainingSchedule.Workouts.Template do
  @moduledoc """
  Workout template strings parser.

  Workout types may define a "template" which determines the description of a workout of this type.
  For instance, an interval session workout could define a template like
  `"{reps}x{distance}@{pace}"`. When a workout of this type is created, the user needs to provide
  a value for `reps`, `distance` and `pace`. Afterwards, these values can be added to the template
  to provide the workout description. Thus if `reps` is `5`, `distance` is `400m` and pace is `5K
  pace`, `"{reps}x{distance}@{pace}"` would be transformed into `5x400m@5Kpace`. This module
  defines the tools used to handle these template strings.
  """

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

  defp parse(nil), do: {:ok, []}

  defp parse(template) do
    case _parse(template) do
      {:ok, parsed, "", _, _, _} -> {:ok, parsed}
      {:error, _, rem, _, _, _} -> {:error, rem}
    end
  end

  @doc """
  Fill in the provided values in the template.

  This function assumes the template string is valid. If it is not valid, a `MatchError` is
  raised. Data is returned as an iolist to prevent unnecessary string allocation.

  ## Examples

      iex> expand("{reps}x{distance}", %{"reps" => "5", "distance" => "400m"})
      ["5", "x", "400m"]
      iex> expand("Race time!", %{"reps" => "5", "distance" => "400m"})
      ["Race time!"]
      iex> expand("{reps}x{distance", %{"reps" => "5", "distance" => "400m"})
      ** (MatchError) no match of right hand side value: {:error, \"{distance\"}
  """
  @spec expand(String.t(), %{String.t() => String.t()}) :: iolist()
  def expand(template, values) do
    {:ok, parsed} = parse(template)

    Enum.map(parsed, fn
      {:field, name} -> values[name] || ""
      any -> any
    end)
  end

  @doc """
  Verify if the template string is valid.

  ## Examples

      iex> validate("{reps}x{distance}")
      :ok
      iex> validate("Race time!")
      :ok
      iex> validate("{reps}x{distance")
      {:error, "{distance"}
  """
  @spec validate(String.t()) :: :ok | {:error, String.t()}
  def validate(template) do
    case parse(template) do
      {:ok, _} -> :ok
      {:error, rem} -> {:error, rem}
    end
  end

  @doc """
  Obtain the fields provided by the template.

  ## Examples

      iex> get_fields("{reps}x{distance}")
      {:ok, ["reps", "distance"]}
      iex> get_fields("Race time!")
      {:ok, []}
      iex> get_fields("{reps}x{distance")
      {:error, "{distance"}
  """
  @spec get_fields(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
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
