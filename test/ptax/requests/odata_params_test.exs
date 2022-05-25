defmodule PTAX.Requests.ODataParamsTest do
  use ExUnit.Case

  alias PTAX.Requests.ODataParams
  alias Tesla.Env

  test "no opts" do
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users"}, [])
    assert env.url == "/Users"
  end

  test "passed opts" do
    opts = [odata: [params: [name: "John"], query: [format: "json"]]]
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users", opts: opts}, [])
    assert env.url == "/Users(name='John')?$format=json"
  end

  test "passed multiple opts" do
    opts = [
      odata: [
        params: [name: "John", age: 20, test: nil],
        query: [filter: [gender: ~w[male female]], format: "json"]
      ]
    ]

    assert {:ok, env} = ODataParams.call(%Env{url: "/Users", opts: opts}, [])

    assert env.url ==
             "/Users(name='John',age='20')?$filter=gender%20in%20('male', 'female')&$format=json"
  end

  test "passed empty opts only" do
    opts = [
      odata: [
        params: [name: nil],
        query: [filter: [gender: nil]]
      ]
    ]

    assert {:ok, env} = ODataParams.call(%Env{url: "/Users", opts: opts}, [])

    assert env.url == "/Users"
  end

  test "passed by middleware opts" do
    assert {:ok, env} = ODataParams.call(%Env{url: "/Users"}, [], query: [format: "json"])
    assert env.url == "/Users?$format=json"
  end
end
