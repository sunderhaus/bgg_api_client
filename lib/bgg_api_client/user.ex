defmodule BggApiClient.User do
  @moduledoc """
  Functions for interacting with the BGG API User endpoint.

  Fetches profile information for a BGG user. Useful for validating that a
  username exists and retrieving the stable numeric BGG user ID.
  """

  import BggApiClient.Params
  import SweetXml

  @doc """
  Retrieves profile information for a BGG user.

  ## Parameters
  - `username`: The BGG username to look up (required)
  - `opts`: Optional parameters:
    - `:buddies` — Include buddy list (boolean)
    - `:guilds` — Include guild memberships (boolean)
    - `:hot` — Include user's hot 10 list (boolean)
    - `:top` — Include user's top 10 list (boolean)
    - `:domain` — Restrict hot/top lists to a domain: `\"boardgame\"` (default),
      `\"rpg\"`, `\"videogame\"`
    - `:page` — Page number for paginated buddies/guilds results

  ## Returns
  - `{:ok, parsed_doc}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> BggApiClient.User.get("someuser")
      {:ok, doc}

      iex> BggApiClient.User.get("someuser", buddies: true, top: true)
      {:ok, doc}
  """
  @spec get(String.t(), keyword()) :: {:ok, any()} | {:error, term()}
  def get(username, opts \\ []) do
    params =
      [name: username]
      |> add_param(:buddies, Keyword.get(opts, :buddies))
      |> add_param(:guilds, Keyword.get(opts, :guilds))
      |> add_param(:hot, Keyword.get(opts, :hot))
      |> add_param(:top, Keyword.get(opts, :top))
      |> add_param(:domain, Keyword.get(opts, :domain))
      |> add_param(:page, Keyword.get(opts, :page))

    case BggApiClient.Client.get("/user", params) do
      {:ok, doc} -> {:ok, parse_user(doc)}
      error -> error
    end
  end

  defp parse_user(doc) do
    %{
      id:                xpath(doc, ~x"/user/@id"s),
      name:              xpath(doc, ~x"/user/@name"s),
      firstname:         xpath(doc, ~x"/user/firstname/@value"s),
      lastname:          xpath(doc, ~x"/user/lastname/@value"s),
      year_registered:   xpath(doc, ~x"/user/yearregistered/@value"s),
      last_login:        xpath(doc, ~x"/user/lastlogin/@value"s),
      state_or_province: xpath(doc, ~x"/user/stateorprovince/@value"s),
      country:           xpath(doc, ~x"/user/country/@value"s),
      avatar_link:       xpath(doc, ~x"/user/avatarlink/@value"s),
      trade_rating:      xpath(doc, ~x"/user/traderating/@value"s)
    }
  end
end
