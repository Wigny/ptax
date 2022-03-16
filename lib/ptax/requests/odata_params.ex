defmodule PTAX.Requests.ODataParams do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, opts \\ []) do
    odata_params = Keyword.get(env.opts, :odata_params, []) ++ opts

    url = build_url(env.url, odata_params)
    Tesla.run(%{env | url: url}, next)
  end

  defp build_url(url, []), do: url

  defp build_url(url, params) do
    query =
      params
      |> Enum.map(fn {key, value} -> "#{key}='#{value}'" end)
      |> Enum.join(",")

    url <> "(#{query})"
  end
end
