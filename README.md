# BggApiClient

An Elixir client for the [BoardGameGeek XML API v2](https://boardgamegeek.com/wiki/page/BGG_XML_API2).

Covers the core BGG API endpoints — Things, Collections, Plays, and Users — with automatic retry
handling for rate-limited and queued responses.

> **Note:** BGG requires a registered application token for all XML API requests.
> See [Using the XML API](https://boardgamegeek.com/using_the_xml_api) to register your application
> and obtain a token before use.

## Features

- **Things** — fetch board games, expansions, accessories, and more by ID (up to 20 at once)
- **Collections** — retrieve a user's collection with rich status and stat filters
- **Plays** — query play records by user and/or game, with date range support
- **Users** — look up BGG user profiles, buddies, guilds, and top/hot lists
- Automatic retry on BGG rate-limit (500/503) and queued (202) responses
- Built on [Tesla](https://github.com/elixir-tesla/tesla) + [Mint](https://github.com/elixir-mint/mint) with [SweetXml](https://github.com/kbrw/sweet_xml) parsing

## Installation

Add `bgg_api_client` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bgg_api_client, github: "sunderhaus/bgg_api_client"}
  ]
end
```

## Configuration

An API token is required for all requests. Obtain one by registering your application at
<https://boardgamegeek.com/applications/create>.

**Environment variable (recommended):**
```bash
export BGG_API_TOKEN=your_token_here
```

**Application config** (`config/config.exs`):
```elixir
config :bgg_api_client, api_token: "your_token_here"
```

**Optional settings:**
```elixir
# Minimum delay in ms between outbound BGG API requests (default: 5000)
config :bgg_api_client, rate_limit_delay: 5000
```

### OTP application

`bgg_api_client` starts its own OTP application, which supervises a `RateLimiter` GenServer that
enforces the delay between requests. This starts automatically when the library is listed as a
dependency — no explicit setup is required in your supervision tree.

**In tests**, the 5-second delay will slow your suite significantly. Disable it in
`config/test.exs`:

```elixir
config :bgg_api_client, rate_limit_delay: 0
```

## Usage

### Things

Fetch one or more games, expansions, or other BGG items by ID:

```elixir
# Single item
{:ok, [thing]} = BggApiClient.Thing.get(359871)

# Multiple items with stats
{:ok, things} = BggApiClient.Thing.get([359871, 167791, 262712], stats: true)

thing.name          #=> "Arcs"
thing.min_players   #=> 2
thing.stats.rank    #=> "53"
```

Supported options: `:type`, `:stats`, `:versions`, `:videos`, `:comments`, `:rss`

### Collections

Retrieve a user's board game collection:

```elixir
# All owned games
{:ok, items} = BggApiClient.Collection.get("username", own: true)

# Expansions with stats
{:ok, items} = BggApiClient.Collection.get("username",
  subtype: "boardgameexpansion",
  stats: true
)

# Items modified since a date
{:ok, items} = BggApiClient.Collection.get("username",
  modified_since: "25-01-01"
)

hd(items).name        #=> "Arcs"
hd(items).num_plays   #=> 4
hd(items).status.own  #=> true
```

### Plays

Query play records for a user and/or game:

```elixir
# All plays for a user
{:ok, result} = BggApiClient.Plays.get("username")

# Plays for a specific game in a date range
{:ok, result} = BggApiClient.Plays.get("username",
  game_id: 359871,
  min_date: "2024-01-01",
  max_date: "2024-12-31"
)

# All recorded plays for a game (across all users)
{:ok, result} = BggApiClient.Plays.get(nil, game_id: 359871)

result.total          #=> 1234
hd(result.plays).date #=> "2024-03-15"
```

### Users

Fetch a BGG user's profile:

```elixir
{:ok, user} = BggApiClient.User.get("username")

# With buddy list and top 10
{:ok, user} = BggApiClient.User.get("username", buddies: true, top: true)

user.name  #=> "username"
user.id    #=> "12345"
```
