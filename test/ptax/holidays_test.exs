defmodule PTAX.HolidaysTest do
  use ExUnit.Case, async: true

  alias PTAX.Holidays

  setup do
    {:ok, holidays_table} =
      "https://www.anbima.com.br/feriados/arqs/feriados_nacionais.xls"
      |> Req.get!(retry: false)
      |> Map.fetch!(:body)
      |> Spreadsheet.parse(sheet: "Feriados", format: :binary)

    holidays =
      for [%NaiveDateTime{} = date, _weekday, _name] <- holidays_table,
          into: MapSet.new(),
          do: NaiveDateTime.to_date(date)

    %{holidays: holidays}
  end

  describe "holiday?/1" do
    test "returns true for exactly the dates on the ANBIMA holidays list", %{holidays: holidays} do
      for date <- Date.range(~D[2001-01-01], ~D[2099-12-31]) do
        assert Holidays.holiday?(date) == MapSet.member?(holidays, date)
      end
    end
  end
end
