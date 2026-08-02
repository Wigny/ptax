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
  Exception for a 7-day window without a single bulletin.
  """

  defexception message: "no quotes published in the last 7 days"
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
