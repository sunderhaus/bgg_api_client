defmodule BggApiClient.Plays do
  @moduledoc """
  Functions for interacting with the BGG API Plays endpoint.

  Retrieves play records for users or games.
  """

  import BggApiClient.Params
  import SweetXml

  @doc """
  Retrieves play records from the BGG API.
  
  Can retrieve plays for a specific username and/or game.
  
  ## Parameters
  - `username`: (optional) The BGG username to retrieve plays for
  - `opts`: Optional parameters:
    - `:game_id`: Filter by game ID (Thing ID)
    - `:min_date`: Start date for plays (YYYY-MM-DD format)
    - `:max_date`: End date for plays (YYYY-MM-DD format)
    - `:comments`: Include comments (default: false)
    - `:stats`: Include statistics (default: false)
  
  Either `:username` or `:opts[:game_id]` must be provided.
  
  ## Returns
  - `{:ok, response}` on success containing the parsed XML as a map
  - `{:error, reason}` on failure
  
  ## Examples
  
      iex> BggApiClient.Plays.get("username")
      {:ok, response}
      
      iex> BggApiClient.Plays.get("username", game_id: 3323, min_date: "2024-01-01")
      {:ok, response}
      
      iex> BggApiClient.Plays.get(nil, game_id: 3323)
      {:ok, response}
  """
  @spec get(String.t() | nil, keyword()) :: {:ok, map()} | {:error, term()}
  def get(username \\ nil, opts \\ []) do
    params = []
    params = add_param(params, :username, username)
    params = add_optional_params(params, opts)
    
    case BggApiClient.Client.get("/plays", params) do
      {:ok, doc} -> {:ok, parse_plays(doc)}
      error -> error
    end
  end

  defp parse_plays(doc) do
    %{
      total: xpath(doc, ~x"/plays/@total"i),
      page:  xpath(doc, ~x"/plays/@page"i),
      plays:
        xpath(doc, ~x"//play"l)
        |> Enum.map(fn play ->
          %{
            id:        xpath(play, ~x"@id"s),
            date:      xpath(play, ~x"@date"s),
            quantity:  xpath(play, ~x"@quantity"i),
            length:    xpath(play, ~x"@length"i),
            game_name: xpath(play, ~x"item/@name"s),
            game_id:   xpath(play, ~x"item/@objectid"s)
          }
        end)
    }
  end

  defp add_optional_params(params, opts) do
    params
    |> add_param(:id, Keyword.get(opts, :game_id))
    |> add_param(:min_date, Keyword.get(opts, :min_date))
    |> add_param(:max_date, Keyword.get(opts, :max_date))
    |> add_param(:comments, Keyword.get(opts, :comments))
    |> add_param(:stats, Keyword.get(opts, :stats))
  end

end
