defmodule PTAX.Requests.Case do
  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    env
    |> encode()
    |> Tesla.run(next)
    |> decode()
  end

  defp encode(%{body: nil} = env), do: env
  defp encode(%{body: body} = env), do: %{env | body: Casex.to_camel_case(body)}

  defp decode({:ok, env}), do: {:ok, Map.update!(env, :body, &Casex.to_snake_case/1)}
  defp decode({:error, error}), do: {:error, error}
end
