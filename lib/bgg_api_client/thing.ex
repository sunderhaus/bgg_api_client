defmodule BggApiClient.Thing do
  @moduledoc """
  Functions for interacting with the BGG API Thing endpoint.
  
  Things are physical, tangible products in the BGG database including:
  - boardgame
  - boardgameexpansion
  - boardgameaccessory
  - videogame
  - rpgitem
  - rpgissue
  """

  import BggApiClient.Params
  import SweetXml

  @doc """
  Retrieves one or more things from the BGG API.
  
  ## Parameters
  - `ids`: A single ID (integer) or list of IDs to retrieve. Max 20 items.
  - `opts`: Optional parameters:
    - `:type`: Filter by thing type (e.g., "boardgame")
    - `:stats`: Include statistics (default: false)
    - `:versions`: Include version info (default: false)
    - `:videos`: Include videos (default: false)
    - `:comments`: Include comments (default: false)
    - `:rss`: Return RSS feed (default: false)
  
  ## Returns
  - `{:ok, response}` on success containing the parsed XML as a map
  - `{:error, reason}` on failure
  
  ## Examples
  
      iex> BggApiClient.Thing.get(3323)
      {:ok, response}
      
      iex> BggApiClient.Thing.get([3323, 1], stats: true)
      {:ok, response}
  """
  @spec get(integer() | [integer()], keyword()) :: {:ok, map()} | {:error, term()}
  def get(ids, opts \\ []) do
    ids_param = format_ids(ids)
    
    params = [id: ids_param]
    params = add_optional_params(params, opts)
    
    case BggApiClient.Client.get("/thing", params) do
      {:ok, doc} -> {:ok, parse_things(doc)}
      error -> error
    end
  end

  defp format_ids(id) when is_integer(id) do
    to_string(id)
  end

  defp format_ids(ids) when is_list(ids) do
    ids
    |> Enum.map(&to_string/1)
    |> Enum.join(",")
  end

  defp parse_things(doc) do
    xpath(doc, ~x"//item"l)
    |> Enum.map(&parse_thing/1)
  end

  defp parse_thing(item) do
    %{
      id:             xpath(item, ~x"@id"s),
      type:           xpath(item, ~x"@type"s),
      name:           xpath(item, ~x"name[@type='primary']/@value"s),
      year_published: xpath(item, ~x"yearpublished/@value"s),
      description:    xpath(item, ~x"description/text()"s),
      image:          xpath(item, ~x"image/text()"s),
      thumbnail:      xpath(item, ~x"thumbnail/text()"s),
      min_players:    xpath(item, ~x"minplayers/@value"i),
      max_players:    xpath(item, ~x"maxplayers/@value"i),
      playing_time:   xpath(item, ~x"playingtime/@value"i),
      links:          parse_thing_links(item),
      stats:          parse_thing_stats(item)
    }
  end

  defp parse_thing_links(item) do
    xpath(item, ~x"link"l)
    |> Enum.map(fn link ->
      %{
        type:    xpath(link, ~x"@type"s),
        id:      xpath(link, ~x"@id"s),
        value:   xpath(link, ~x"@value"s),
        inbound: xpath(link, ~x"@inbound"s)
      }
    end)
  end

  defp parse_thing_stats(item) do
    case xpath(item, ~x"statistics/ratings/average/@value"s) do
      "" ->
        nil

      _ ->
        %{
          avg_rating:  xpath(item, ~x"statistics/ratings/average/@value"s),
          bayes_avg:   xpath(item, ~x"statistics/ratings/bayesaverage/@value"s),
          num_ratings: xpath(item, ~x"statistics/ratings/usersrated/@value"i),
          rank:        xpath(item, ~x"statistics/ratings/ranks/rank[@name='boardgame']/@value"s)
        }
    end
  end

  defp add_optional_params(params, opts) do
    params
    |> add_param(:type, Keyword.get(opts, :type))
    |> add_param(:stats, Keyword.get(opts, :stats))
    |> add_param(:versions, Keyword.get(opts, :versions))
    |> add_param(:videos, Keyword.get(opts, :videos))
    |> add_param(:comments, Keyword.get(opts, :comments))
    |> add_param(:rss, Keyword.get(opts, :rss))
  end

end
