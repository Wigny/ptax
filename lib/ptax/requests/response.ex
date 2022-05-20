defmodule PTAX.Requests.Response do
  @behaviour Tesla.Middleware

  alias PTAX.Error

  defguardp is_empty(value) when value == []
  defguardp is_success(status) when status in 200..299
  defguardp is_client_error(status) when status in 400..499
  defguardp is_server_error(status) when status in 500..599

  @impl true
  def call(env, next, _opts) do
    env
    |> Tesla.run(next)
    |> response()
  end

  defp response({:ok, %{body: %{"value" => value}, status: status} = env})
       when is_success(status) and not is_empty(value) do
    {:ok, %{env | body: value}}
  end

  defp response({:ok, %{body: body, status: status}}) when is_success(status) do
    error =
      Error.new(
        code: :not_found,
        message: "Data not found",
        status: status,
        details: body
      )

    {:error, error}
  end

  defp response({:ok, %{body: body, status: status}}) when is_client_error(status) do
    details =
      if captures = Regex.named_captures(~r"/\*(?<details>[\S\s]*?)\*/", body),
        do: Jason.decode!(captures["details"])

    error =
      Error.new(
        code: :client_error,
        message: details["mensagem"],
        status: status,
        details: details
      )

    {:error, error}
  end

  defp response({:ok, %{body: body, status: status}}) when is_server_error(status) do
    error =
      Error.new(
        code: :server_error,
        message: "Unknown error",
        status: status,
        details: body
      )

    {:error, error}
  end

  defp response({:error, error}) do
    error = Error.new(code: :network_error, message: "Request error", details: error)
    {:error, error}
  end
end
