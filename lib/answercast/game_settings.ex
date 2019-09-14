defmodule Answercast.GameSettings do
  defstruct(
    max_clients: 16,
    max_players: 12,
    max_viewers: 4,

    # TODO: increase this for realistic conditions
    client_timeout: 600
  )
end
