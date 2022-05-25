defmodule PTAX.Requests.ODataParams do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, opts \\ []) do
    odata_opts = opts(env.opts, opts)

    url = build_url(env.url, odata_opts)
    Tesla.run(%{env | url: url}, next)
  end

  defp opts(env_opts, opts) do
    env_opts
    |> Keyword.get(:odata, [])
    |> Keyword.merge(opts, fn _k, v1, v2 -> v1 ++ v2 end)
    |> Map.new()
  end

  defp build_url(url, opts) do
    join = if String.contains?(url, "?"), do: "&", else: "?"

    params = if p = encode_params(opts[:params]), do: "(#{p})", else: ""
    query = if q = encode_query(opts[:query]), do: join <> q, else: ""

    url <> params <> query
  end

  defp encode_params({_key, nil}) do
    nil
  end

  defp encode_params({key, value}) do
    "#{key}='#{value}'"
  end

  defp encode_params(value) when is_list(value) do
    encode_keyword_list(value, &encode_params/1, ",")
  end

  defp encode_params(value) do
    value
  end

  defp encode_query({_key, nil}) do
    nil
  end

  defp encode_query({key, value}) do
    if v = encode_query_value(value), do: "$#{key}=#{v}"
  end

  defp encode_query(value) when is_list(value) do
    encode_keyword_list(value, &encode_query/1, "&")
  end

  defp encode_query(value) do
    value
  end

  defp encode_query_value({_key, nil}) do
    nil
  end

  defp encode_query_value({_key, []}) do
    nil
  end

  defp encode_query_value({key, values}) when is_list(values) do
    "#{key}%20in%20(#{Enum.map_join(values, ", ", &"'#{&1}'")})"
  end

  defp encode_query_value({key, value}) do
    "#{key}%20eq%20'#{value}'"
  end

  defp encode_query_value(value) when is_list(value) do
    encode_keyword_list(value, &encode_query_value/1, " and ")
  end

  defp encode_query_value(value) do
    value
  end

  defp encode_keyword_list(list, encoder, joiner) do
    list = list |> Enum.map(&then(&1, encoder)) |> Enum.reject(&is_nil/1)

    unless Enum.empty?(list) do
      Enum.join(list, joiner)
    end
  end
end
