defmodule BggApiClient.Collection do
  @moduledoc """
  Functions for interacting with the BGG API Collection endpoint.

  Retrieves a user's board game collection.
  """

  import BggApiClient.Params
  import SweetXml

  @doc """
  Retrieves a user's collection from the BGG API.

  ## Parameters
  - `username`: The BGG username whose collection to retrieve
  - `opts`: Optional parameters:

  **Content filters**
    - `:subtype` — Filter by subtype: `"boardgame"` (default), `"boardgameexpansion"`,
      `"boardgameaccessory"`, `"rpgitem"`, `"rpgissue"`, `"videogame"`
    - `:exclude_subtype` — Exclude items matching this subtype
    - `:id` — Restrict to specific BGG Thing IDs (integer or comma-separated string)
    - `:brief` — Return abbreviated results with no stats (boolean)
    - `:collection_id` — Restrict to a specific collection ID
    - `:modified_since` — Only items changed after this date (`"YY-MM-DD"` or `"YY-MM-DD HH:MM:SS"`)

  **Status filters**
    - `:own` — Include owned items
    - `:rated` — Include rated items
    - `:played` — Include played items
    - `:comment` — Include items with a comment
    - `:trade` — Include items for trade
    - `:want` — Include wanted items
    - `:wishlist` — Include wishlist items
    - `:wishlist_priority` — Minimum wishlist priority (1–5)
    - `:preordered` — Include preordered items
    - `:want_to_play` — Include "want to play" items
    - `:want_to_buy` — Include "want to buy" items
    - `:prev_owned` — Include previously owned items
    - `:has_parts` — Include items where owner has parts
    - `:want_parts` — Include items where owner wants parts

  **Stats / rating filters**
    - `:stats` — Include statistics in response (boolean)
    - `:version` — Include version info (boolean)
    - `:min_rating` — Minimum user personal rating
    - `:rating` — Exact user personal rating
    - `:min_bgg_rating` — Minimum BGG community rating
    - `:bgg_rating` — Exact BGG community rating
    - `:min_plays` — Minimum recorded play count
    - `:max_plays` — Maximum recorded play count
    - `:showprivate` — Include private collection info (requires auth as collection owner)

  ## Returns
  - `{:ok, parsed_doc}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> BggApiClient.Collection.get("username")
      {:ok, response}

      iex> BggApiClient.Collection.get("username", subtype: "boardgame", stats: true)
      {:ok, response}

      iex> BggApiClient.Collection.get("username", subtype: "boardgameexpansion", modified_since: "25-01-01")
      {:ok, response}
  """
  @spec get(String.t(), keyword()) :: {:ok, any()} | {:error, term()}
  def get(username, opts \\ []) do
    params =
      [username: username]
      |> add_param(:subtype, Keyword.get(opts, :subtype))
      |> add_param(:excludesubtype, Keyword.get(opts, :exclude_subtype))
      |> add_param(:id, Keyword.get(opts, :id))
      |> add_param(:brief, Keyword.get(opts, :brief))
      |> add_param(:collid, Keyword.get(opts, :collection_id))
      |> add_param(:modifiedsince, Keyword.get(opts, :modified_since))
      |> add_param(:own, Keyword.get(opts, :own))
      |> add_param(:rated, Keyword.get(opts, :rated))
      |> add_param(:played, Keyword.get(opts, :played))
      |> add_param(:comment, Keyword.get(opts, :comment))
      |> add_param(:trade, Keyword.get(opts, :trade))
      |> add_param(:want, Keyword.get(opts, :want))
      |> add_param(:wishlist, Keyword.get(opts, :wishlist))
      |> add_param(:wishlistpriority, Keyword.get(opts, :wishlist_priority))
      |> add_param(:preordered, Keyword.get(opts, :preordered))
      |> add_param(:wanttoplay, Keyword.get(opts, :want_to_play))
      |> add_param(:wanttobuy, Keyword.get(opts, :want_to_buy))
      |> add_param(:prevowned, Keyword.get(opts, :prev_owned))
      |> add_param(:hasparts, Keyword.get(opts, :has_parts))
      |> add_param(:wantparts, Keyword.get(opts, :want_parts))
      |> add_param(:stats, Keyword.get(opts, :stats))
      |> add_param(:version, Keyword.get(opts, :version))
      |> add_param(:minrating, Keyword.get(opts, :min_rating))
      |> add_param(:rating, Keyword.get(opts, :rating))
      |> add_param(:minbggrating, Keyword.get(opts, :min_bgg_rating))
      |> add_param(:bggrating, Keyword.get(opts, :bgg_rating))
      |> add_param(:minplays, Keyword.get(opts, :min_plays))
      |> add_param(:maxplays, Keyword.get(opts, :max_plays))
      |> add_param(:showprivate, Keyword.get(opts, :showprivate))

    case BggApiClient.Client.get("/collection", params) do
      {:ok, doc} -> {:ok, parse_items(doc)}
      error -> error
    end
  end

  defp parse_items(doc) do
    xpath(doc, ~x"//item"l)
    |> Enum.map(&parse_item/1)
  end

  defp parse_item(item) do
    %{
      bgg_id:        xpath(item, ~x"@objectid"s),
      subtype:       xpath(item, ~x"@subtype"s),
      coll_id:       xpath(item, ~x"@collid"s),
      name:          xpath(item, ~x"name/text()"s),
      year_published: xpath(item, ~x"yearpublished/text()"s),
      image:         xpath(item, ~x"image/text()"s),
      thumbnail:     xpath(item, ~x"thumbnail/text()"s),
      num_plays:     xpath(item, ~x"numplays/text()"i),
      status: %{
        own:           xpath(item, ~x"status/@own"s) == "1",
        prev_owned:    xpath(item, ~x"status/@prevowned"s) == "1",
        for_trade:     xpath(item, ~x"status/@fortrade"s) == "1",
        want:          xpath(item, ~x"status/@want"s) == "1",
        want_to_play:  xpath(item, ~x"status/@wanttoplay"s) == "1",
        want_to_buy:   xpath(item, ~x"status/@wanttobuy"s) == "1",
        wishlist:      xpath(item, ~x"status/@wishlist"s) == "1",
        preordered:    xpath(item, ~x"status/@preordered"s) == "1",
        last_modified: xpath(item, ~x"status/@lastmodified"s)
      },
      stats: parse_item_stats(item)
    }
  end

  # BGG omits the <stats> element entirely when stats=1 was not requested.
  defp safe_integer(""), do: nil
  defp safe_integer(str), do: String.to_integer(str)

  # BGG omits the <stats> element entirely when stats=1 was not requested.
  # We detect its absence by checking whether the element exists at all.
  defp parse_item_stats(item) do
    case xpath(item, ~x"stats"l) do
      [] ->
        nil

      _ ->
        %{
          min_players:  safe_integer(xpath(item, ~x"stats/@minplayers"s)),
          max_players:  safe_integer(xpath(item, ~x"stats/@maxplayers"s)),
          playing_time: safe_integer(xpath(item, ~x"stats/@playingtime"s)),
          rating:       xpath(item, ~x"stats/rating/@value"s),
          bgg_avg:      xpath(item, ~x"stats/rating/average/@value"s),
          bgg_bayes:    xpath(item, ~x"stats/rating/bayesaverage/@value"s),
          num_rated:    safe_integer(xpath(item, ~x"stats/rating/usersrated/@value"s)),
          rank:         xpath(item, ~x"stats/rating/ranks/rank[@name='boardgame']/@value"s)
        }
    end
  end
end
