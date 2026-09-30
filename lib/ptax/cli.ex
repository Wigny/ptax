defmodule PTAX.CLI do
  @moduledoc false

  @version Mix.Project.config()[:version]

  def main(args) do
    case OptionParser.parse(args,
           strict: [date: :string, help: :boolean, version: :boolean],
           aliases: [d: :date, h: :help, v: :version]
         ) do
      {[version: true], [], []} -> IO.puts("ptax #{@version}")
      {[help: true], [], []} -> IO.puts(usage())
      {options, [amount, from, to], []} -> run(amount, from, to, options[:date])
      _invalid -> halt(usage(), 64)
    end
  end

  defp run(amount, from_currency, to_currency, date) do
    with {:ok, money} <- parse_money(from_currency, amount),
         {:ok, date} <- parse_date(date),
         {:ok, exchanged} <- exchange(money, to_currency, date) do
      IO.puts(Money.to_string!(exchanged))
    else
      {:error, exception} -> halt("ptax: #{Exception.message(exception)}", 1)
    end
  end

  defp parse_money(currency, amount) do
    case Money.new(currency, amount) do
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
    Usage: ptax <amount> <from> <to> [--date <YYYY-MM-DD>]

    Converts an amount between two currencies at the Brazilian Central Bank's PTAX rate.
    Without --date the latest published bulletin is used.

    Options:
      -d, --date <YYYY-MM-DD>  Use the bulletin published for this date
      -v, --version            Print the version
      -h, --help               Print this help

    Examples:
      ptax 100 USD BRL
      ptax 50 GBP BRL --date 2026-07-31
    """
  end

  defp halt(message, status) do
    IO.puts(:stderr, message)
    exit({:shutdown, status})
  end
end
