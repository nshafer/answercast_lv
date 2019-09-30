defmodule Answercast.Game do
  alias __MODULE__
  alias Answercast.{GameSettings, Client}

  @valid_states [:idle, :poll, :results]

  defstruct(
    id: nil,
    hashids: nil,
    state: :idle,
    started: nil,
    last_update: nil,
    players: %{},
    viewers: %{},
    settings: %GameSettings{},
    answers: []
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

  def add_player(game, name) do
    client_id = get_client_id(game)
    new_player = Client.new(client_id, :player, name)
    {new_player, %Game{refresh(game) | players: Map.put(game.players, new_player.id, new_player)}}
  end
  
  def add_viewer(game) do
    client_id = get_client_id(game)
    new_viewer = Client.new(client_id, :viewer)
    {new_viewer, %Game{refresh(game) | viewers: Map.put(game.viewers, new_viewer.id, new_viewer)}}
  end
  
  def add_client(game, type, name \\ nil) do
    case type do
      :player -> add_player(game, name)
      :viewer -> add_viewer(game)
    end
  end

  def update_player(game, player) do
    %Game{refresh(game) | players: Map.put(game.players, player.id, player)}
  end
  
  def update_viewer(game, viewer) do
    %Game{refresh(game) | viewers: Map.put(game.viewers, viewer.id, viewer)}
  end
  
  def update_client(game, client) do
    case client.type do
      :player -> update_player(game, client)
      :viewer -> update_viewer(game, client)
    end
  end

  def remove_player(game, player) do
    %Game{refresh(game) | players: Map.delete(game.players, player.id)}
  end

  def remove_viewer(game, viewer) do
    %Game{refresh(game) | viewers: Map.delete(game.viewers, viewer.id)}
  end

  def remove_client(game, client) do
    case client.type do
      :player -> remove_player(game, client)
      :viewer -> remove_viewer(game, client)
    end
  end

  def change_state(game, state) when state in @valid_states do
    %Game{refresh(game) | state: state}
  end

  # Accessors

  def num_players(game), do: map_size(game.players)
  def num_viewers(game), do: map_size(game.viewers)
  def num_clients(game), do: num_players(game) + num_viewers(game)

  def players(game), do: Map.values(game.players)

  def viewers(game), do: Map.values(game.viewers)

  def clients(game), do: players(game) ++ viewers(game)

  def clients(game, type) do
    case type do
      :player -> players(game)
      :viewer -> viewers(game)
    end
  end

  def get_client_by_id(game, client_id) do
    Map.get(game.players, client_id) || Map.get(game.viewers, client_id)
  end

  def get_client_by_name(game, name) do
    normalized_name = normalize_name(name)

    players(game)
    |> Enum.find(fn client -> normalize_name(client.name) == normalized_name end)
  end

  # Utils
  def normalize_game_id(game_id) when is_binary(game_id) do
    game_id |> String.trim() |> String.slice(0..3) |> String.upcase()
  end

  def normalize_name(name) when is_binary(name) do
    name |> String.trim() |> String.upcase()
  end
  
  def get_client_id(game) do
    Hashids.encode(game.hashids, System.unique_integer([:positive, :monotonic]))
  end

  def valid_states() do
    @valid_states
  end
end
