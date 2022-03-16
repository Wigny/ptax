defmodule PTAX.RequestsTest do
  use ExUnit.Case

  alias PTAX.Requests

  describe "requests" do
    test "response/1 returns ok if the result is valid" do
      result = {:ok, %Tesla.Env{body: %{"value" => [true]}, status: 200}}
      assert {:ok, [true]} = Requests.response(result)
    end

    test "response/1 throws `:not_found` error if no data is returned in result" do
      result = {:ok, %Tesla.Env{status: 200}}
      assert {:error, %PTAX.Error{code: :not_found}} = Requests.response(result)
    end

    test "response/1 throws `:server_error` error if there is a server error" do
      result = {:ok, %Tesla.Env{status: 500}}
      assert {:error, %PTAX.Error{code: :server_error}} = Requests.response(result)
    end

    test "response/1 throws `network_error` error if there is an error making the request" do
      result = {:error, nil}
      assert {:error, %PTAX.Error{code: :network_error}} = Requests.response(result)
    end
  end
end
