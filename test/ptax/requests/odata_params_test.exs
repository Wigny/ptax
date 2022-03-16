defmodule PTAX.Requests.ODataParamsTest do
  use ExUnit.Case

  alias PTAX.Requests.ODataParams
  alias Tesla.Env

  test "no params" do
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users"}, [])
    assert env.url == "/Users"
  end

  test "passed params" do
    opts = [odata_params: [name: "John"]]
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users", opts: opts}, [])
    assert env.url == "/Users(name='John')"
  end

  test "passed multiple params" do
    opts = [odata_params: [name: "John", age: 20]]
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users", opts: opts}, [])
    assert env.url == "/Users(name='John',age='20')"
  end

  test "passed opts" do
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users"}, [], age: 20)
    assert env.url == "/Users(age='20')"
  end
end
