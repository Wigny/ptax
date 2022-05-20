defmodule PTAX.Requests.ODataParams do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, opts \\ []) do
    odata_opts =
      env.opts
      |> Keyword.get(:odata, [])
      |> Keyword.merge(opts, fn _k, v1, v2 -> v1 ++ v2 end)

    url = build_url(env.url, Map.new(odata_opts))
    Tesla.run(%{env | url: url}, next)
  end

  defp build_url(url, opts) do
    join = if String.contains?(url, "?"), do: "&", else: "?"

    (url <> encode_params(opts[:params]) <> encode_query(join, opts[:query])) |> IO.inspect()
  end

  defp encode_params(nil) do
    ""
  end

  defp encode_params(params) do
    encoded =
      params
      |> Enum.map(fn
        {_key, nil} -> nil
        {key, value} -> "#{key}='#{value}'"
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(",")

    "(#{encoded})"
  end

  defp encode_query(_join, nil) do
    ""
  end

  defp encode_query(join, query) do
    encoded =
      query
      |> Enum.map(fn
        {_key, nil} ->
          nil

        {key, value} ->
          value = encode_query_value(value)
          if value != "", do: "$#{key}=#{value}", else: nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("&")

    if "" != encoded, do: join <> encoded, else: encoded
  end

  defp encode_query_value(value) when is_binary(value) do
    value
  end

  defp encode_query_value(value) when is_list(value) do
    Enum.map(value, fn
      {_key, nil} ->
        nil

      {key, values} when is_list(values) ->
        "#{key} in (#{Enum.map_join(values, ", ", &"'#{&1}'")})"

      {key, value} ->
        "#{key}%20eq%20'#{value}'"
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" and ")
    |> IO.inspect()
  end
end
