defmodule BggApiClient.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BggApiClient.RateLimiter
    ]

    opts = [strategy: :one_for_one, name: BggApiClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
