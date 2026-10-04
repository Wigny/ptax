defmodule PTAX.Holidays do
  @moduledoc false

  @doc """
  Returns whether `date` is a Brazilian national holiday on which BCB publishes no bulletin.

  The fixed holidays are New Year's Day, Tiradentes, Labour Day, Independence Day, Our Lady of
  Aparecida, All Souls' Day, Proclamation of the Republic and Christmas, plus Black Consciousness
  Day from 2024 onwards. The movable ones follow Easter: Carnival Monday and Tuesday, Good Friday
  and Corpus Christi.
  """
  @spec holiday?(Date.t()) :: boolean

  for {month, day} <- [{1, 1}, {4, 21}, {5, 1}, {9, 7}, {10, 12}, {11, 2}, {11, 15}, {12, 25}] do
    def holiday?(%Date{month: unquote(month), day: unquote(day)}), do: true
  end

  def holiday?(%Date{year: year, month: 11, day: 20}), do: year >= 2024

  def holiday?(%Date{} = date), do: Date.diff(date, easter(date.year)) in [-48, -47, -2, 60]

  defp easter(year) do
    a = rem(year, 19)
    b = div(year, 100)
    c = rem(year, 100)
    h = rem(19 * a + b - div(b, 4) - div(b - div(b + 8, 25) + 1, 3) + 15, 30)
    l = rem(32 + 2 * rem(b, 4) + 2 * div(c, 4) - h - rem(c, 4), 7)
    m = div(a + 11 * h + 22 * l, 451)
    n = h + l - 7 * m + 114

    Date.new!(year, div(n, 31), rem(n, 31) + 1)
  end
end
