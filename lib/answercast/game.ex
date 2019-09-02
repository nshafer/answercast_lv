defmodule Answercast.Game do
  alias __MODULE__
  alias Answercast.{GameSettings, Player}

  defstruct(
    game_id: nil,
    status: :idle,
    players: [],
    settings: %GameSettings{}
  )

  def new(game_id) do
    %Game{game_id: game_id}
  end

  def add_player(%Game{players: players} = game, %Player{} = player) do
    %Game{game | players: [player | players]}
  end
end
