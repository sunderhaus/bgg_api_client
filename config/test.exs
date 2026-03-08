import Config

# Use Tesla's built-in mock adapter in tests so HTTP calls are intercepted
config :bgg_api_client, tesla_adapter: Tesla.Mock

# Zero retry delay so tests don't wait on retries
config :bgg_api_client, rate_limit_delay: 0
