#!/usr/bin/env elixir

Mix.start()
Mix.Project.in_project(:bgg_api_client, ".", fn _module ->
  Mix.Task.run("compile")
end)

require Logger

Logger.configure(level: :info)

# Read API token from environment variable
# Token can be obtained from https://boardgamegeek.com/applications/create
token = System.get_env("BGG_API_TOKEN")

if token do
  Application.put_env(:bgg_api_client, :api_token, token)
  IO.puts("✓ BGG_API_TOKEN configured")
else
  IO.puts("⚠ BGG_API_TOKEN not set. Testing without authentication.")
end

# Test 1: Fetch a specific thing (Arcs - ID 359871)
IO.puts("\n=== Test 1: Fetch Thing (Arcs) ===")

case BggApiClient.Thing.get(359871) do
  {:ok, doc} ->
    IO.puts("✓ Successfully fetched thing")
    # Extract some basic info
    name = BggApiClient.Parser.xpath_string(doc, "//item/name[@type='primary']/text()")
    year = BggApiClient.Parser.xpath_string(doc, "//item/yearpublished/text()")
    IO.puts("  Name: #{name}")
    IO.puts("  Year: #{year}")
  
  {:error, reason} ->
    IO.puts("✗ Failed to fetch thing: #{inspect(reason)}")
end

# Test 2: Fetch user's collection
IO.puts("\n=== Test 2: Fetch User Collection ===")

case BggApiClient.Collection.get("sunderhaus") do
  {:ok, doc} ->
    IO.puts("✓ Successfully fetched collection")
    # Extract number of items
    items = BggApiClient.Parser.xpath_list(doc, "//item/@objectid")
    IO.puts("  Total items in collection: #{length(items)}")
    
    # Show first few items
    if length(items) > 0 do
      IO.puts("  First few item IDs: #{items |> Enum.take(5) |> Enum.join(", ")}")
    end
  
  {:error, reason} ->
    IO.puts("✗ Failed to fetch collection: #{inspect(reason)}")
end

# Test 3: Fetch user's plays
IO.puts("\n=== Test 3: Fetch User Plays ===")

case BggApiClient.Plays.get("sunderhaus") do
  {:ok, doc} ->
    IO.puts("✓ Successfully fetched plays")
    # Extract number of play records
    plays = BggApiClient.Parser.xpath_list(doc, "//play")
    IO.puts("  Total play records: #{length(plays)}")
  
  {:error, reason} ->
    IO.puts("✗ Failed to fetch plays: #{inspect(reason)}")
end

# Test 4: Fetch multiple things
IO.puts("\n=== Test 4: Fetch Multiple Things ===")

case BggApiClient.Thing.get([359871, 167791, 262712]) do
  {:ok, doc} ->
    IO.puts("✓ Successfully fetched multiple things")
    names = BggApiClient.Parser.xpath_list(doc, "//item/name[@type='primary']/text()")
    IO.puts("  Games: #{Enum.join(names, ", ")}")
  
  {:error, reason} ->
    IO.puts("✗ Failed to fetch things: #{inspect(reason)}")
end

IO.puts("\n=== Tests Complete ===\n")
