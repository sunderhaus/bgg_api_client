defmodule BggApiClient.RateLimiter do
  @moduledoc """
  Enforces a minimum delay between BGG API requests to comply with BGG's
  rate-limiting expectations (~5 seconds between requests).

  All requests through `BggApiClient.Client` call `acquire/0` before executing.
  This serializes outbound BGG API calls with a configurable delay between them
  (default: 5000ms, configured via `BggApiClient.Config.rate_limit_delay/0`).

  If the GenServer is not running (e.g. in tests), `acquire/0` is a no-op.
  Set `config :bgg_api_client, rate_limit_delay: 0` to disable the delay
  in tests while still running the GenServer.
  """

  use GenServer

  @doc """
  Blocks the caller until at least `rate_limit_delay` milliseconds have elapsed
  since the last request was started. No-op if the GenServer is not running.
  """
  @spec acquire() :: :ok
  def acquire do
    case Process.whereis(__MODULE__) do
      nil -> :ok
      _pid -> GenServer.call(__MODULE__, :acquire, :infinity)
    end
  end

  # --- Supervisor child spec ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --- GenServer callbacks ---

  @impl true
  def init(_opts) do
    # last_request_at: monotonic ms of the last acquire, or nil
    {:ok, nil}
  end

  @impl true
  def handle_call(:acquire, _from, last_request_at) do
    delay = BggApiClient.Config.rate_limit_delay()
    now = System.monotonic_time(:millisecond)

    if delay > 0 && last_request_at != nil do
      elapsed = now - last_request_at

      if elapsed < delay do
        Process.sleep(delay - elapsed)
      end
    end

    {:reply, :ok, System.monotonic_time(:millisecond)}
  end
end
