defmodule PTAX.Holidays do
  @moduledoc false

  @url "https://www.anbima.com.br/feriados/arqs/feriados_nacionais.xls"

  {:ok, _apps} = Application.ensure_all_started(:req)
  %{body: file} = Req.get!(@url, retry: false)
  {:ok, rows} = Spreadsheet.parse(file, sheet: "Feriados", format: :binary)

  @dates for [%NaiveDateTime{} = date, _weekday, _name] <- rows,
             into: MapSet.new(),
             do: NaiveDateTime.to_date(date)

  @spec holiday?(Date.t()) :: boolean
  def holiday?(%Date{} = date), do: MapSet.member?(@dates, date)
end
