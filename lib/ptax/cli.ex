defmodule PTAX.CLI do
  @moduledoc false

  @version Mix.Project.config()[:version]

  @parse_options [
    strict: [to: :string, date: :string, help: :boolean, version: :boolean],
    aliases: [t: :to, d: :date, h: :help, v: :version]
  ]

  def main(args) do
    args
    |> OptionParser.parse(@parse_options)
    |> run()
  end

  defp run({[version: true], [], []}), do: IO.puts("ptax #{@version}")
  defp run({[help: true], [], []}), do: IO.puts(usage())
  defp run({_options, [], _invalid}), do: halt(usage(), 64)
  defp run({_options, _money, invalid}) when length(invalid) > 0, do: halt(usage(), 64)

  defp run({options, money, []}) do
    with {:ok, money} <- parse_money(Enum.join(money, " ")),
         {:ok, date} <- parse_date(options[:date]),
         {:ok, exchanged} <- exchange(money, options[:to] || "BRL", date) do
      IO.puts(Money.to_string!(exchanged))
    else
      {:error, exception} -> halt("ptax: #{Exception.message(exception)}", 1)
    end
  end

  defp parse_money(string) do
    case Money.parse(string) do
      %Money{} = money -> {:ok, money}
      {:error, {module, reason}} -> {:error, module.exception(reason)}
    end
  end

  defp parse_date(nil), do: {:ok, nil}

  defp parse_date(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> {:ok, date}
      {:error, _reason} -> {:error, ArgumentError.exception("invalid date: #{date}")}
    end
  end

  defp exchange(money, currency, nil), do: PTAX.exchange(money, currency)
  defp exchange(money, currency, date), do: PTAX.exchange(money, currency, date)

  defp usage do
    """
    Usage: ptax <money> [--to <currency>] [--date <YYYY-MM-DD>]

    Converts an amount of money at the Brazilian Central Bank's PTAX rate.
    <money> is an amount with a currency code or symbol, such as "100 USD" or "US$ 100".
    Without --to the amount is converted to BRL.
    Without --date the latest published bulletin is used.

    Options:
      -t, --to <currency>      Convert to this currency instead of BRL
      -d, --date <YYYY-MM-DD>  Use the bulletin published for this date
      -v, --version            Print the version
      -h, --help               Print this help

    Examples:
      ptax 100 USD
      ptax "US$ 100"
      ptax 100 BRL --to USD
      ptax 50 GBP --date 2026-07-31
    """
  end

  defp halt(message, status) do
    IO.puts(:stderr, message)
    exit({:shutdown, status})
  end
end
