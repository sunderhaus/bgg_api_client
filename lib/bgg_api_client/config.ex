defmodule BggApiClient.Config do
  @moduledoc """
  Configuration module for the BGG API client.
  
  Provides functions to retrieve API configuration including base URL and credentials.
  """

  @base_url "https://boardgamegeek.com/xmlapi2"

  @doc """
  Returns the base URL for the BGG API.
  """
  @spec base_url() :: String.t()
  def base_url do
    @base_url
  end

  @doc """
  Returns the API token from configuration.
  Falls back to application config or environment variable.
  
  The token is obtained from https://boardgamegeek.com/applications/create
  """
  @spec api_token() :: String.t() | nil
  def api_token do
    get_config(:api_token, "BGG_API_TOKEN")
  end

  @doc """
  Returns the rate limit delay in milliseconds (default: 5000ms for 5-second rate limit).
  """
  @spec rate_limit_delay() :: pos_integer()
  def rate_limit_delay do
    Application.get_env(:bgg_api_client, :rate_limit_delay, 5000)
  end

  defp get_config(key, env_var) do
    Application.get_env(:bgg_api_client, key) || System.get_env(env_var)
  end
end
