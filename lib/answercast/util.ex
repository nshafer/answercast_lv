defmodule Answercast.Util do
  alias Answercast.{GameSupervisor}

  @valid_game_id_chars 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

  def generate_new_game_id() do
    new_game_id =
      @valid_game_id_chars
      |> Enum.take_random(4)
      |> to_string

    case GameSupervisor.game_exists?(new_game_id) do
      true -> generate_new_game_id()
      false -> new_game_id
    end
  end
end
