defmodule PTAX.RequestsTest do
  use ExUnit.Case

  alias PTAX.Requests

  describe "requests" do
    test "response/1 retorna ok se o result for valido" do
      result = {:ok, %Tesla.Env{body: %{"value" => [true]}, status: 200}}
      assert {:ok, [true]} = Requests.response(result)
    end

    test "response/1 retorna erro `:not_found` se nenhum dado for retornado no result" do
      result = {:ok, %Tesla.Env{status: 200}}
      assert {:error, %PTAX.Error{code: :not_found}} = Requests.response(result)
    end

    test "response/1 retorna erro `:server_error` se houver erro de servidor" do
      result = {:ok, %Tesla.Env{status: 500}}
      assert {:error, %PTAX.Error{code: :server_error}} = Requests.response(result)
    end

    test "response/1 retorna erro `network_error` se ocorrer erro ao realizar request" do
      result = {:error, nil}
      assert {:error, %PTAX.Error{code: :network_error}} = Requests.response(result)
    end
  end
end
