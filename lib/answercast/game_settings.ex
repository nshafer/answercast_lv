defmodule Answercast.GameSettings do
  defstruct(
    max_players: 12,
    player_timeout: 60  # TODO: increase this for realistic conditions
  )
end
