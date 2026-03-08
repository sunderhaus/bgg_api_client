defmodule BggApiClient.Client do
  @moduledoc """
  HTTP client for the BGG API using Tesla and Mint.

  Provides a configured HTTP client with optional authentication.
  Retries on rate limit errors (500/503) and queued responses (202) using
  the configured rate limit delay.
  """

  require Logger

  @doc """
  Makes a GET request to the BGG API.

  Retries on rate limit errors (500/503) and BGG-queued responses (202).

  ## Parameters
  - `path`: The API endpoint path (e.g., "/thing")
  - `params`: Query parameters as a keyword list
  - `opts`: Options including `:max_retries` (default: 3)

  ## Returns
  - `{:ok, parsed_doc}` on success — body parsed via `BggApiClient.Parser`
  - `{:error, reason}` on failure
  """
  @spec get(String.t(), keyword(), keyword()) :: {:ok, any()} | {:error, term()}
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
      {Tesla.Middleware.Headers, default_headers()}
    ]

    adapter = Application.get_env(:bgg_api_client, :tesla_adapter, {Tesla.Adapter.Mint, []})
    Tesla.client(middleware, adapter)
  end

  defp do_get(path, params, retries_remaining) do
    client()
    |> Tesla.get(path, query: params)
    |> handle_response(path, params, retries_remaining)
  end

  defp default_headers do
    headers = [{"user-agent", "BggApiClient/0.1.0"}]

    case BggApiClient.Config.api_token() do
      token when is_binary(token) ->
        [{"authorization", "Bearer #{token}"} | headers]

      _ ->
        headers
    end
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries)
       when status in [200, 201] do
    BggApiClient.Parser.parse(body)
  end

  defp handle_response({:ok, %Tesla.Env{status: 202}}, path, params, retries) do
    retry_or_fail(path, params, retries, 202, "queued")
  end

  defp handle_response({:ok, %Tesla.Env{status: status}}, path, params, retries)
       when status in [500, 503] do
    retry_or_fail(path, params, retries, status, "rate limited")
  end

  defp handle_response({:ok, %Tesla.Env{status: 401}}, _path, _params, _retries) do
    {:error, {:unauthorized, "BGG API requires a valid token. Set the BGG_API_TOKEN environment variable or configure :api_token in your application config."}}
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries)
       when status >= 400 do
    {:error, {:http_error, status, body}}
  end

  defp handle_response({:ok, %Tesla.Env{status: status, body: body}}, _path, _params, _retries) do
    {:error, {:unexpected_status, status, body}}
  end

  defp handle_response({:error, reason}, _path, _params, _retries) do
    {:error, {:request_failed, reason}}
  end

  defp retry_or_fail(path, params, retries, status, label) do
    delay = BggApiClient.Config.rate_limit_delay()

    if retries > 0 do
      Logger.warning("BGG API #{label} (#{status}): retrying in #{delay}ms...")
      Process.sleep(delay)
      do_get(path, params, retries - 1)
    else
      Logger.error("BGG API #{label} (#{status}): max retries exceeded")
      {:error, {:rate_limited, status}}
    end
  end
end
