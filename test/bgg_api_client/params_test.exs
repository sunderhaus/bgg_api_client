defmodule BggApiClient.ParamsTest do
  use ExUnit.Case, async: true

  alias BggApiClient.Params

  describe "add_param/3" do
    test "omits nil values" do
      assert Params.add_param([], :stats, nil) == []
    end

    test "omits false values" do
      assert Params.add_param([], :stats, false) == []
    end

    test "converts true to integer 1" do
      assert Params.add_param([], :stats, true) == [stats: 1]
    end

    test "passes through string values" do
      assert Params.add_param([], :subtype, "boardgame") == [subtype: "boardgame"]
    end

    test "passes through integer values" do
      assert Params.add_param([], :page, 2) == [page: 2]
    end

    test "appends to an existing list" do
      assert Params.add_param([username: "alice"], :stats, true) == [username: "alice", stats: 1]
    end

    test "chaining multiple calls" do
      result =
        []
        |> Params.add_param(:own, true)
        |> Params.add_param(:rated, nil)
        |> Params.add_param(:subtype, "boardgame")

      assert result == [own: 1, subtype: "boardgame"]
    end
  end
end
