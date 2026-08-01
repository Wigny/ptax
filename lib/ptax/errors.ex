defmodule PTAX.QuotesNotFoundError do
  @moduledoc false

  defexception [:date]

  @impl true
  def message(%{date: date}) do
    "no quotes published for #{date}"
  end
end

defmodule PTAX.LatestQuotesNotFoundError do
  @moduledoc false

  defexception message: "no quotes published in the last 7 days"
end
