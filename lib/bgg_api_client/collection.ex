defmodule BggApiClient.Collection do
  @moduledoc """
  Functions for interacting with the BGG API Collection endpoint.
  
  Retrieves a user's board game collection.
  """

  @doc """
  Retrieves a user's collection from the BGG API.
  
  ## Parameters
  - `username`: The BGG username whose collection to retrieve
  - `opts`: Optional parameters:
    - `:own`: Include owned items (default: true)
    - `:rated`: Include rated items (default: true)
    - `:played`: Include played items (default: true)
    - `:comment`: Include comments (default: false)
    - `:trade`: Include items for trade (default: true)
    - `:want`: Include items on want list (default: true)
    - `:wishlist`: Include items on wishlist (default: true)
    - `:wishlist_priority`: Minimum wishlist priority (1-5)
    - `:preordered`: Include preordered items (default: true)
    - `:exclude_subtype`: Exclude by subtype
    - `:version`: Include version info (default: false)
    - `:stats`: Include statistics (default: false)
  
  ## Returns
  - `{:ok, response}` on success containing the parsed XML as a map
  - `{:error, reason}` on failure
  
  ## Examples
  
      iex> BggApiClient.Collection.get("username")
      {:ok, response}
      
      iex> BggApiClient.Collection.get("username", stats: true, rated: true)
      {:ok, response}
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(username, opts \\ []) do
    params = [username: username]
    params = add_optional_params(params, opts)
    
    BggApiClient.Client.get("/collection", params)
  end

  defp add_optional_params(params, opts) do
    params
    |> add_param(:own, Keyword.get(opts, :own))
    |> add_param(:rated, Keyword.get(opts, :rated))
    |> add_param(:played, Keyword.get(opts, :played))
    |> add_param(:comment, Keyword.get(opts, :comment))
    |> add_param(:trade, Keyword.get(opts, :trade))
    |> add_param(:want, Keyword.get(opts, :want))
    |> add_param(:wishlist, Keyword.get(opts, :wishlist))
    |> add_param(:wishlist_priority, Keyword.get(opts, :wishlist_priority))
    |> add_param(:exclude_subtype, Keyword.get(opts, :exclude_subtype))
    |> add_param(:version, Keyword.get(opts, :version))
    |> add_param(:stats, Keyword.get(opts, :stats))
  end

  defp add_param(params, _key, nil), do: params
  defp add_param(params, _key, false), do: params
  defp add_param(params, key, true), do: params ++ [{key, 1}]
  defp add_param(params, key, value), do: params ++ [{key, value}]
end
