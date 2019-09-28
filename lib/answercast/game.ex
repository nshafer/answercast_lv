defmodule Answercast.Game do
  alias __MODULE__
  alias Answercast.{GameSettings, Client}

  defstruct(
    id: nil,
    hashids: nil,
    status: :idle,
    started: nil,
    last_update: nil,
    clients: %{},
    settings: %GameSettings{}
  )

  def new(game_id) do
    %Game{
      id: game_id,
      started: DateTime.utc_now(),
      last_update: DateTime.utc_now(),
      hashids: Hashids.new(salt: game_id, min_len: 4)
    }
  end

  def refresh(game) do
    %Game{game | last_update: DateTime.utc_now()}
  end

  # Mutators

  def change_settings(game, %GameSettings{} = settings) do
    %Game{refresh(game) | settings: settings}
  end

  def add_client(game, type, name \\ nil) do
    client_id = Hashids.encode(game.hashids, System.unique_integer([:positive, :monotonic]))
    new_client = Client.new(client_id, type, name)
    {new_client, %Game{refresh(game) | clients: Map.put(game.clients, new_client.id, new_client)}}
  end

  def update_client(game, client) do
    %Game{refresh(game) | clients: Map.put(game.clients, client.id, client)}
  end

  def remove_client(game, client) do
    %Game{refresh(game) | clients: Map.delete(game.clients, client.id)}
  end

  # Accessors

  def clients(game) do
    Map.values(game.clients)
  end

  def clients(game, type) do
    if type do
      clients(game)
      |> Enum.filter(fn client -> client.type == type end)
    else
      clients(game)
    end
  end

  def get_client_by_id(game, client_id) do
    Map.get(game.clients, client_id)
  end

  def get_client_by_name(game, name) do
    normalized_name = normalize_name(name)

    clients(game, :player)
    |> Enum.find(fn client -> normalize_name(client.name) == normalized_name end)
  end

  # Utils
  def normalize_game_id(game_id) when is_binary(game_id) do
    game_id |> String.trim() |> String.slice(0..3) |> String.upcase()
  end

  def normalize_name(name) when is_binary(name) do
    name |> String.trim() |> String.upcase()
  end
end
