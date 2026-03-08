defmodule BggApiClient.UserTest do
  use ExUnit.Case, async: false

  import Tesla.Mock

  @user_xml ~s(<?xml version="1.0" encoding="utf-8"?>
<user id="123456" name="testuser">
  <firstname value="Test"/>
  <lastname value="User"/>
  <yearregistered value="2010"/>
  <lastlogin value="2024-01-15"/>
  <stateorprovince value="CA"/>
  <country value="United States"/>
  <traderating value="100"/>
  <avatarlink value="https://example.com/avatar.jpg"/>
</user>)

  defp capture_request(username, opts) do
    {:ok, agent} = Agent.start_link(fn -> nil end)

    mock(fn env ->
      Agent.update(agent, fn _ -> env end)
      %Tesla.Env{status: 200, body: @user_xml}
    end)

    BggApiClient.User.get(username, opts)
    Agent.get(agent, & &1)
  end

  describe "get/2 — parameter building" do
    test "sends name param" do
      env = capture_request("testuser", [])
      assert Keyword.get(env.query, :name) == "testuser"
    end

    test "sends buddies as 1" do
      env = capture_request("testuser", buddies: true)
      assert Keyword.get(env.query, :buddies) == 1
    end

    test "sends guilds as 1" do
      env = capture_request("testuser", guilds: true)
      assert Keyword.get(env.query, :guilds) == 1
    end

    test "sends hot as 1" do
      env = capture_request("testuser", hot: true)
      assert Keyword.get(env.query, :hot) == 1
    end

    test "sends top as 1" do
      env = capture_request("testuser", top: true)
      assert Keyword.get(env.query, :top) == 1
    end

    test "sends domain string" do
      env = capture_request("testuser", domain: "rpg")
      assert Keyword.get(env.query, :domain) == "rpg"
    end

    test "sends page number" do
      env = capture_request("testuser", page: 2)
      assert Keyword.get(env.query, :page) == 2
    end

    test "omits optional params when not provided" do
      env = capture_request("testuser", [])
      assert env.query == [name: "testuser"]
    end
  end

  describe "get/2 — response parsing" do
    test "returns a map with user id and name" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @user_xml} end)

      assert {:ok, user} = BggApiClient.User.get("testuser")

      assert user.id == "123456"
      assert user.name == "testuser"
    end

    test "maps all profile fields" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @user_xml} end)

      assert {:ok, user} = BggApiClient.User.get("testuser")

      assert user.firstname == "Test"
      assert user.lastname == "User"
      assert user.country == "United States"
      assert user.year_registered == "2010"
      assert user.last_login == "2024-01-15"
      assert user.state_or_province == "CA"
      assert user.trade_rating == "100"
      assert user.avatar_link == "https://example.com/avatar.jpg"
    end
  end
end
