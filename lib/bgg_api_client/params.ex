defmodule BggApiClient.Params do
  @moduledoc """
  Shared helpers for building BGG API query parameter lists.
  """

  @doc """
  Appends `{key, value}` to `params` with the following rules:

  - `nil` — omitted (parameter not set)
  - `false` — omitted
  - `true` — appended as `{key, 1}` (BGG uses `1`/`0` for booleans)
  - any other value — appended as-is

  ## Examples

      iex> BggApiClient.Params.add_param([], :stats, true)
      [stats: 1]

      iex> BggApiClient.Params.add_param([], :subtype, "boardgame")
      [subtype: "boardgame"]

      iex> BggApiClient.Params.add_param([stats: 1], :own, nil)
      [stats: 1]
  """
  @spec add_param(keyword(), atom(), term()) :: keyword()
  def add_param(params, _key, nil), do: params
  def add_param(params, _key, false), do: params
  def add_param(params, key, true), do: params ++ [{key, 1}]
  def add_param(params, key, value), do: params ++ [{key, value}]
end
