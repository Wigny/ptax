defmodule PTAX.Quotes.FileCache do
  @moduledoc false

  @spec attach(Req.Request.t()) :: Req.Request.t()
  def attach(request) do
    request
    |> Req.Request.register_options([:cache_dir])
    |> Req.Request.merge_new_options(cache_dir: :filename.basedir(:user_cache, ~c"ptax"))
    |> Req.Request.append_request_steps(read_from_cache: &read_from_cache/1)
    |> Req.Request.append_response_steps(save_to_cache: &save_to_cache/1)
  end

  defp read_from_cache(%{options: %{cache_dir: nil}} = request) do
    request
  end

  defp read_from_cache(request) do
    case File.read(filepath(request)) do
      {:ok, content} ->
        response =
          [status: 200, body: content]
          |> Req.Response.new()
          |> Req.Response.put_private(:cached, true)

        {request, response}

      {:error, _reason} ->
        request
    end
  end

  defp save_to_cache({%{options: %{cache_dir: nil}}, _response} = result) do
    result
  end

  defp save_to_cache({_request, %{private: %{cached: true}}} = result) do
    result
  end

  defp save_to_cache({request, %{status: 200} = response}) do
    write_atomically(filepath(request), response.body)

    {request, response}
  end

  defp save_to_cache(result) do
    result
  end

  defp write_atomically(path, content) do
    tmp_path = "#{path}.#{System.unique_integer([:positive])}"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(tmp_path, content),
         :ok <- File.rename(tmp_path, path) do
      :ok
    else
      _error -> File.rm(tmp_path)
    end
  end

  defp filepath(request) do
    Path.join(request.options.cache_dir, Path.basename(request.url.path))
  end
end
