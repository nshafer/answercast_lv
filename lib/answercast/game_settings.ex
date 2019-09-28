defmodule Answercast.GameSettings do
  defstruct(
    max_players: 12,
    max_viewers: 1,

    # TODO: increase this for realistic conditions
    client_timeout: 60 * 5
  )
end
