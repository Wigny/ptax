defmodule PTAX.ExchangeRates.StubAdapter do
  @moduledoc false

  def run(request) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)

    today_date = Calendar.strftime(today, "%Y%m%d")
    yesterday_date = Calendar.strftime(yesterday, "%Y%m%d")

    {request,
     case request.options.path_params[:date] do
       ^today_date ->
         Req.Response.new(status: 404)

       ^yesterday_date ->
         Req.Response.new(
           status: 200,
           body:
             "#{Calendar.strftime(yesterday, "%d/%m/%Y")};220;A;USD;5,00000000;5,00000000;1,00000000;1,00000000\r\n"
         )

       "20260515" ->
         Req.Response.new(
           status: 200,
           body: """
           15/05/2026;220;A;USD;5,06480000;5,06540000;1,00000000;1,00000000\r
           15/05/2026;540;B;GBP;6,75190000;6,75320000;1,33310000;1,33320000\r
           15/05/2026;978;B;EUR;5,88830000;5,89000000;1,16260000;1,16280000\r
           """
         )

       "20260610" ->
         Req.Response.new(
           status: 200,
           body: "10/06/2026;220;A;USD;5,10000000;5,20000000;1,00000000;1,00000000\r\n"
         )

       "20251225" ->
         Req.Response.new(status: 404)

       "20260101" ->
         %Req.TransportError{reason: :timeout}
     end}
  end
end
