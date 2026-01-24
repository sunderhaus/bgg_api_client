defmodule BggApiClient.Parser do
  @moduledoc """
  Utilities for parsing BGG API XML responses.
  
  Converts XML responses to Elixir-friendly data structures using SweetXml.
  """

  require Logger
  import SweetXml

  @doc """
  Parses an XML response string into a map structure.
  
  ## Parameters
  - `xml_string`: The XML response body as a string
  
  ## Returns
  - `{:ok, parsed_map}` on success
  - `{:error, reason}` on failure
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, term()}
  def parse(xml_string) when is_binary(xml_string) do
    try do
      doc = SweetXml.parse(xml_string)
      {:ok, doc}
    rescue
      e ->
        Logger.error("Failed to parse XML: #{inspect(e)}")
        {:error, {:parse_error, e}}
    end
  end

  def parse(_), do: {:error, :invalid_input}

  @doc """
  Extracts a single string value using XPath.
  
  ## Examples
  
      iex> doc = SweetXml.parse("<root><name>Test</name></root>")
      iex> BggApiClient.Parser.xpath_string(doc, "//name/text()")
      "Test"
  """
  @spec xpath_string(any(), String.t()) :: String.t() | nil
  def xpath_string(doc, path) do
    try do
      SweetXml.xpath(doc, ~x"#{path}"s)
    rescue
      _ -> nil
    end
  end

  @doc """
  Extracts a list of values using XPath.
  
  ## Examples
  
      iex> doc = SweetXml.parse("<root><item><id>1</id></item><item><id>2</id></item></root>")
      iex> BggApiClient.Parser.xpath_list(doc, "//item/id/text()")
      ["1", "2"]
  """
  @spec xpath_list(any(), String.t()) :: [String.t()]
  def xpath_list(doc, path) do
    try do
      SweetXml.xpath(doc, ~x"#{path}"l)
    rescue
      _ -> []
    end
  end

  @doc """
  Extracts elements using XPath and maps them with the provided function.
  
  Useful for extracting lists of structured items from the API response.
  
  ## Examples
  
      iex> doc = SweetXml.parse("<root><item id=\"1\"><name>Game</name></item></root>")
      iex> BggApiClient.Parser.xpath_elements(doc, "//item", fn elem ->
      ...>   %{id: SweetXml.xpath(elem, ~x"@id"s), name: SweetXml.xpath(elem, ~x"./name/text()"s)}
      ...> end)
      [%{id: "1", name: "Game"}]
  """
  @spec xpath_elements(any(), String.t(), (any() -> map())) :: [map()]
  def xpath_elements(doc, path, mapper) do
    try do
      doc
      |> SweetXml.xpath(~x"#{path}"l)
      |> Enum.map(mapper)
    rescue
      _ -> []
    end
  end

  @doc """
  Extracts an integer value using XPath.
  """
  @spec xpath_integer(any(), String.t()) :: integer() | nil
  def xpath_integer(doc, path) do
    case xpath_string(doc, path) do
      nil -> nil
      str -> 
        try do
          String.to_integer(str)
        rescue
          _ -> nil
        end
    end
  end

  @doc """
  Extracts a float value using XPath.
  """
  @spec xpath_float(any(), String.t()) :: float() | nil
  def xpath_float(doc, path) do
    case xpath_string(doc, path) do
      nil -> nil
      str ->
        try do
          String.to_float(str)
        rescue
          _ -> nil
        end
    end
  end
end
