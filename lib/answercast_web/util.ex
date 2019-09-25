defmodule AnswercastWeb.Util do
  alias Answercast.GameSupervisor

  def valid_game_id(game_id) do
    String.length(game_id) == 4 and GameSupervisor.game_exists?(game_id)
  end

  def game_id_found(game_id) do
    case String.length(game_id) do
      4 -> GameSupervisor.game_exists?(game_id)
      _ -> nil
    end
  end

  def valid_name(name) do
    String.length(name) > 0
  end
end
