defmodule BggApiClientTest do
  use ExUnit.Case
  doctest BggApiClient

  test "greets the world" do
    assert BggApiClient.hello() == :world
  end
end
