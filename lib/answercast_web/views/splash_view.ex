defmodule AnswercastWeb.SplashView do
  use AnswercastWeb, :view
  alias Answercast.{GameSupervisor, GameManager}

  def valid_game_id?(game_id) do
    String.length(game_id) == 4 and GameSupervisor.game_exists?(game_id)
  end

  def valid_name?(name) do
    String.length(name) > 0
  end

  def valid_name?(game_id, name) do
    String.length(name) > 0 and not name_in_use?(game_id, name)
  end

  def game_id_found?(game_id) do
    case String.length(game_id) do
      4 -> GameSupervisor.game_exists?(game_id)
      _ -> nil
    end
  end

  def name_in_use?(game_id, name) do
    if valid_game_id?(game_id) do
      case GameSupervisor.existing_game(game_id) do
        {:ok, game} -> GameManager.name_in_use?(game, name)
        _ -> nil
      end
    end
  end
end
