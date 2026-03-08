defmodule BggApiClient.ClientTest do
  use ExUnit.Case, async: false

  import Tesla.Mock

  @minimal_xml ~s(<?xml version="1.0" encoding="utf-8"?><items totalitems="0"/>)

  describe "get/3 — success" do
    test "returns parsed XML doc on 200" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @minimal_xml} end)

      assert {:ok, _doc} = BggApiClient.Client.get("/collection", username: "alice")
    end

    test "returns parsed XML doc on 201" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 201, body: @minimal_xml} end)

      assert {:ok, _doc} = BggApiClient.Client.get("/thing", id: "174430")
    end
  end

  describe "get/3 — 202 retry (queued)" do
    test "retries on 202 and succeeds on next attempt" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      mock(fn %{method: :get} ->
        count = Agent.get_and_update(agent, fn c -> {c, c + 1} end)

        if count == 0 do
          %Tesla.Env{status: 202, body: ""}
        else
          %Tesla.Env{status: 200, body: @minimal_xml}
        end
      end)

      assert {:ok, _doc} = BggApiClient.Client.get("/collection", username: "alice")
      assert Agent.get(agent, & &1) == 2
    end

    test "returns error after exhausting retries on 202" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 202, body: ""} end)

      assert {:error, {:rate_limited, 202}} =
               BggApiClient.Client.get("/collection", [username: "alice"], max_retries: 0)
    end
  end

  describe "get/3 — rate limit retry (500/503)" do
    test "retries on 500 and succeeds on next attempt" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      mock(fn %{method: :get} ->
        count = Agent.get_and_update(agent, fn c -> {c, c + 1} end)

        if count == 0 do
          %Tesla.Env{status: 500, body: ""}
        else
          %Tesla.Env{status: 200, body: @minimal_xml}
        end
      end)

      assert {:ok, _doc} = BggApiClient.Client.get("/thing", id: "174430")
    end

    test "retries on 503 and succeeds on next attempt" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      mock(fn %{method: :get} ->
        count = Agent.get_and_update(agent, fn c -> {c, c + 1} end)

        if count == 0 do
          %Tesla.Env{status: 503, body: ""}
        else
          %Tesla.Env{status: 200, body: @minimal_xml}
        end
      end)

      assert {:ok, _doc} = BggApiClient.Client.get("/thing", id: "174430")
    end

    test "returns error after exhausting retries on 500" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 500, body: ""} end)

      assert {:error, {:rate_limited, 500}} =
               BggApiClient.Client.get("/thing", [id: "174430"], max_retries: 0)
    end
  end

  describe "get/3 — HTTP errors" do
    test "returns unauthorized error with helpful message on 401" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 401, body: ""} end)

      assert {:error, {:unauthorized, message}} =
               BggApiClient.Client.get("/collection", username: "alice")

      assert message =~ "BGG_API_TOKEN"
    end

    test "returns http_error for other 4xx responses" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 404, body: "not found"} end)

      assert {:error, {:http_error, 404, "not found"}} =
               BggApiClient.Client.get("/collection", username: "nobody")
    end
  end
end
