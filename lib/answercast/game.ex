defmodule Answercast.Game do
  alias __MODULE__
  alias Answercast.{GameSettings, Client}

  defstruct(
    id: nil,
    hashids: nil,
    status: :idle,
    clients: [],
    settings: %GameSettings{}
  )

  def new(game_id) do
    %Game{id: game_id, hashids: Hashids.new(salt: game_id, min_len: 4)}
  end

  def add_client(game, pid, type, name \\ nil) do
    client_id = Hashids.encode(game.hashids, System.unique_integer([:positive, :monotonic]))
    new_client = Client.new(client_id, pid, type, name)
    {new_client, %Game{game | clients: [new_client | game.clients]}}
  end

  def clients(game) do
    game.clients
  end

  def clients(game, type) do
    if type do
      Enum.filter(game.clients, fn client -> client.type == type end)
    else
      game.clients
    end
  end
end
