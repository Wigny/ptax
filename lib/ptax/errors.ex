defmodule PTAX.QuotesNotFoundError do
  @moduledoc """
  Exception for a date BCB has no bulletin for, such as a weekend or a holiday.
  """

  defexception [:date]

  @impl true
  def message(%{date: date}) do
    "no quotes published for #{date}"
  end
end

defmodule PTAX.LatestQuotesNotFoundError do
  @moduledoc """
  Exception for the latest two business days without a bulletin.
  """

  defexception message: "no quotes published for the latest two business days"
end

defmodule PTAX.CurrencyNotQuotedError do
  @moduledoc """
  Exception for a currency the bulletin does not quote.
  """

  defexception [:currency]

  @impl true
  def message(%{currency: currency}) do
    "PTAX does not quote #{inspect(currency)}"
  end
end

defmodule PTAX.UnexpectedResponseError do
  @moduledoc """
  Exception for a response with a status other than 200 or 404.
  """

  defexception [:status]

  @impl true
  def message(%{status: status}) do
    "BCB responded with an unexpected status: #{status}"
  end
end
