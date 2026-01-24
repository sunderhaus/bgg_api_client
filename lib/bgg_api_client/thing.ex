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

  require Logger

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
    
    BggApiClient.Client.get("/thing", params)
  end

  defp format_ids(id) when is_integer(id) do
    to_string(id)
  end

  defp format_ids(ids) when is_list(ids) do
    ids
    |> Enum.map(&to_string/1)
    |> Enum.join(",")
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

  defp add_param(params, _key, nil), do: params
  defp add_param(params, _key, false), do: params
  defp add_param(params, key, true), do: params ++ [{key, 1}]
  defp add_param(params, key, value), do: params ++ [{key, value}]
end
