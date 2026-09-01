defmodule BggApiClient.ThingTest do
  use ExUnit.Case, async: false

  import Tesla.Mock

  @item_xml ~s(<?xml version="1.0" encoding="utf-8"?>
<items>
  <item type="boardgame" id="174430">
    <name type="primary" sortindex="1" value="Gloomhaven"/>
    <yearpublished value="2017"/>
    <image>//cf.geekdo-images.com/thumb.jpg</image>
    <thumbnail>//cf.geekdo-images.com/thumb_s.jpg</thumbnail>
    <description>A game of tactical combat.</description>
    <minplayers value="1"/>
    <maxplayers value="4"/>
    <playingtime value="120"/>
    <link type="boardgamemechanic" id="2001" value="Action Points"/>
    <statistics page="1">
      <ratings>
        <usersrated value="67891"/>
        <average value="8.54169"/>
        <bayesaverage value="8.42456"/>
        <ranks>
          <rank type="subtype" id="1" name="boardgame" friendlyname="Board Game Rank" value="1"/>
        </ranks>
      </ratings>
    </statistics>
  </item>
</items>)

  describe "get/2 — response shape" do
    test "returns a list of parsed things" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(174_430)

      assert thing.id == "174430"
      assert thing.type == "boardgame"
      assert thing.name == "Gloomhaven"
      assert thing.year_published == "2017"
      assert thing.description == "A game of tactical combat."
      assert thing.min_players == 1
      assert thing.max_players == 4
      assert thing.playing_time == 120
    end

    test "parses stats when present" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(174_430)

      assert thing.stats.avg_rating == "8.54169"
      assert thing.stats.bayes_avg == "8.42456"
      assert thing.stats.num_ratings == 67_891
      assert thing.stats.rank == "1"
    end

    test "parses links" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(174_430)

      assert [%{type: "boardgamemechanic", id: "2001", value: "Action Points"}] = thing.links
    end
  end

  # BGG returns some item types (accessories, and some rpgitem/videogame
  # things) with player-count/playtime/rating attributes present but empty,
  # rather than omitting the element. SweetXml's `i` type cast on such a
  # value raises ArgumentError (:erlang.binary_to_integer("")) instead of
  # returning nil, which crashed BggApiClient.Thing.get/2 for any batch that
  # included one of these — regression coverage for that fix.
  @item_with_empty_integers_xml ~s(<?xml version="1.0" encoding="utf-8"?>
<items>
  <item type="boardgameaccessory" id="999999">
    <name type="primary" sortindex="1" value="Dice Tower"/>
    <yearpublished value="2020"/>
    <image>//cf.geekdo-images.com/thumb.jpg</image>
    <thumbnail>//cf.geekdo-images.com/thumb_s.jpg</thumbnail>
    <description>An accessory with no player count.</description>
    <minplayers value=""/>
    <maxplayers value=""/>
    <playingtime value=""/>
    <statistics page="1">
      <ratings>
        <usersrated value=""/>
        <average value="0"/>
        <bayesaverage value="0"/>
        <ranks>
          <rank type="subtype" id="1" name="boardgame" friendlyname="Board Game Rank" value="Not Ranked"/>
        </ranks>
      </ratings>
    </statistics>
  </item>
</items>)

  describe "get/2 — empty integer attributes" do
    test "returns nil for min_players, max_players, playing_time when @value is empty" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_with_empty_integers_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(999_999)

      assert thing.min_players == nil
      assert thing.max_players == nil
      assert thing.playing_time == nil
    end

    test "returns nil for stats.num_ratings when usersrated @value is empty" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_with_empty_integers_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(999_999)

      assert thing.stats.num_ratings == nil
    end

    test "does not raise, and still returns non-integer fields" do
      mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: @item_with_empty_integers_xml} end)

      assert {:ok, [thing]} = BggApiClient.Thing.get(999_999)

      assert thing.name == "Dice Tower"
      assert thing.stats.rank == "Not Ranked"
    end
  end
end
