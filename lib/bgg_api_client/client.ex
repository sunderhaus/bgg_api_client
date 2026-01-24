defmodule BggApiClient.Client do
  @moduledoc """
  HTTP client for the BGG API using Tesla and Mint.
  
  Provides a configured HTTP client with optional authentication.
  Retries on rate limit errors (500/503) with a 5-second delay.
  """

  require Logger

  @doc """
  Makes a GET request to the BGG API.
  
  Retries on rate limit errors (500/503) with a 5-second delay.
  
  ## Parameters
  - `path`: The API endpoint path (e.g., "/thing")
  - `params`: Query parameters as a keyword list
  - `opts`: Options including `:max_retries` (default: 3)
  
  ## Returns
  - `{:ok, response}` on success
  - `{:error, reason}` on failure
  """
  @spec get(String.t(), keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(path, params \\ [], opts \\ []) do
    max_retries = Keyword.get(opts, :max_retries, 3)
    do_get(path, params, max_retries)
  end

  @doc """
  Returns a Tesla client configured with Mint adapter and authentication.
  """
  @spec client() :: Tesla.Client.t()
  def client do
    middleware = [
      {Tesla.Middleware.BaseUrl, BggApiClient.Config.base_url()},
      {Tesla.Middleware.Headers, default_headers()},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware, {Tesla.Adapter.Mint, []})
  end

  defp do_get(path, params, retries_remaining) do
    client()
    |> Tesla.get(path, query: params)
    |> handle_response(path, params, retries_remaining)
  end

  defp default_headers do
    headers = [{"user-agent", "BggApiClient/0.1.0"}]
    
    # BGG XML API uses Bearer token authentication
    case BggApiClient.Config.api_token() do
      token when is_binary(token) ->
        [{"authorization", "Bearer #{token}"} | headers]
      
      _ ->
        headers
    end
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries) when status in [200, 201] do
    {:ok, body}
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: _body}}, path, params, retries) when status in [500, 503] do
    if retries > 0 do
      Logger.warning("BGG API rate limited (#{status}): retrying in 5 seconds...")
      Process.sleep(5000)
      do_get(path, params, retries - 1)
    else
      Logger.error("BGG API rate limited (#{status}): max retries exceeded")
      {:error, {:rate_limited, status}}
    end
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries) when status >= 400 do
    {:error, {:http_error, status, body}}
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries) do
    {:error, {:unexpected_status, status, body}}
  end

  defp handle_response({:error, reason}, _path, _params, _retries) do
    {:error, {:request_failed, reason}}
  end
end
