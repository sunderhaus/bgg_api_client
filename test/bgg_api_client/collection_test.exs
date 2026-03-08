defmodule BggApiClient.CollectionTest do
  use ExUnit.Case, async: false

  import Tesla.Mock

  @minimal_xml ~s(<?xml version="1.0" encoding="utf-8"?><items totalitems="0"/>)

  defp capture_request(opts) do
    {:ok, agent} = Agent.start_link(fn -> nil end)

    mock(fn env ->
      Agent.update(agent, fn _ -> env end)
      %Tesla.Env{status: 200, body: @minimal_xml}
    end)

    BggApiClient.Collection.get("testuser", opts)
    Agent.get(agent, & &1)
  end

  describe "get/2 — required param" do
    test "always sends username" do
      env = capture_request([])
      assert Keyword.get(env.query, :username) == "testuser"
    end
  end

  describe "get/2 — content filters" do
    test "sends subtype when provided" do
      env = capture_request(subtype: "boardgameexpansion")
      assert Keyword.get(env.query, :subtype) == "boardgameexpansion"
    end

    test "omits subtype when not provided" do
      env = capture_request([])
      refute Keyword.has_key?(env.query, :subtype)
    end

    test "sends id filter" do
      env = capture_request(id: 174_430)
      assert Keyword.get(env.query, :id) == 174_430
    end

    test "sends brief as 1" do
      env = capture_request(brief: true)
      assert Keyword.get(env.query, :brief) == 1
    end

    test "sends modifiedsince" do
      env = capture_request(modified_since: "25-01-01")
      assert Keyword.get(env.query, :modifiedsince) == "25-01-01"
    end

    test "sends collid" do
      env = capture_request(collection_id: 9999)
      assert Keyword.get(env.query, :collid) == 9999
    end
  end

  describe "get/2 — status filters" do
    test "sends own as 1" do
      env = capture_request(own: true)
      assert Keyword.get(env.query, :own) == 1
    end

    test "sends wanttoplay as 1" do
      env = capture_request(want_to_play: true)
      assert Keyword.get(env.query, :wanttoplay) == 1
    end

    test "sends wanttobuy as 1" do
      env = capture_request(want_to_buy: true)
      assert Keyword.get(env.query, :wanttobuy) == 1
    end

    test "sends prevowned as 1" do
      env = capture_request(prev_owned: true)
      assert Keyword.get(env.query, :prevowned) == 1
    end

    test "sends hasparts as 1" do
      env = capture_request(has_parts: true)
      assert Keyword.get(env.query, :hasparts) == 1
    end

    test "sends wantparts as 1" do
      env = capture_request(want_parts: true)
      assert Keyword.get(env.query, :wantparts) == 1
    end
  end

  @item_xml ~s(<?xml version="1.0" encoding="utf-8"?>
<items totalitems="1">
  <item objecttype="thing" objectid="174430" subtype="boardgame" collid="12345">
    <name sortindex="1">Gloomhaven</name>
    <yearpublished>2017</yearpublished>
    <image>//cf.geekdo-images.com/thumb.jpg</image>
    <thumbnail>//cf.geekdo-images.com/thumb_s.jpg</thumbnail>
    <status own="1" prevowned="0" fortrade="0" want="0" wanttoplay="1"
            wanttobuy="0" wishlist="0" preordered="0"
            lastmodified="2021-06-01 00:00:00"/>
    <numplays>5</numplays>
  </item>
</items>)

  @item_with_stats_xml ~s(<?xml version="1.0" encoding="utf-8"?>
<items totalitems="1">
  <item objecttype="thing" objectid="174430" subtype="boardgame" collid="12345">
    <name sortindex="1">Gloomhaven</name>
    <yearpublished>2017</yearpublished>
    <image>//cf.geekdo-images.com/thumb.jpg</image>
    <thumbnail>//cf.geekdo-images.com/thumb_s.jpg</thumbnail>
    <stats minplayers="1" maxplayers="4" minplaytime="60" maxplaytime="120" playingtime="120" numowned="100000">
      <rating value="9">
        <usersrated value="67891"/>
        <average value="8.54169"/>
        <bayesaverage value="8.42456"/>
        <ranks>
          <rank type="subtype" id="1" name="boardgame" value="1" bayesaverage="8.42456"/>
        </ranks>
      </rating>
    </stats>
    <status own="1" prevowned="0" fortrade="0" want="0" wanttoplay="0"
            wanttobuy="0" wishlist="0" preordered="0"
            lastmodified="2021-06-01 00:00:00"/>
    <numplays>5</numplays>
  </item>
</items>)

  describe "get/2 — response shape" do
    test "returns a list of parsed items" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [item]} = BggApiClient.Collection.get("testuser")

      assert item.bgg_id == "174430"
      assert item.subtype == "boardgame"
      assert item.coll_id == "12345"
      assert item.name == "Gloomhaven"
      assert item.year_published == "2017"
      assert item.num_plays == 5
    end

    test "maps status flags to booleans" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [item]} = BggApiClient.Collection.get("testuser")

      assert item.status.own == true
      assert item.status.prev_owned == false
      assert item.status.want_to_play == true
      assert item.status.last_modified == "2021-06-01 00:00:00"
    end

    test "stats is nil when stats were not requested" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [item]} = BggApiClient.Collection.get("testuser")

      assert item.stats == nil
    end

    test "stats map is populated when stats=true was requested" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_with_stats_xml} end)

      assert {:ok, [item]} = BggApiClient.Collection.get("testuser", stats: true)

      assert item.stats.min_players == 1
      assert item.stats.max_players == 4
      assert item.stats.playing_time == 120
      assert item.stats.rating == "9"
      assert item.stats.bgg_avg == "8.54169"
      assert item.stats.rank == "1"
    end

    test "returns empty list when collection has no items" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @minimal_xml} end)

      assert {:ok, []} = BggApiClient.Collection.get("testuser")
    end
  end

  describe "get/2 — stats / rating filters" do
    test "sends stats as 1" do
      env = capture_request(stats: true)
      assert Keyword.get(env.query, :stats) == 1
    end

    test "sends minrating" do
      env = capture_request(min_rating: 7)
      assert Keyword.get(env.query, :minrating) == 7
    end

    test "sends minbggrating" do
      env = capture_request(min_bgg_rating: 6.5)
      assert Keyword.get(env.query, :minbggrating) == 6.5
    end

    test "sends minplays and maxplays" do
      env = capture_request(min_plays: 1, max_plays: 10)
      assert Keyword.get(env.query, :minplays) == 1
      assert Keyword.get(env.query, :maxplays) == 10
    end

    test "sends showprivate as 1" do
      env = capture_request(showprivate: true)
      assert Keyword.get(env.query, :showprivate) == 1
    end
  end
end
