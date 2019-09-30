defmodule AnswercastWeb.GameView do
  use AnswercastWeb, :view
  alias Answercast.{Game,Client}

  def me(%{assigns: assigns} = _socket) do
    Game.get_client_by_id(assigns.game, assigns.client_id)
  end

  def me(%{game: game, client_id: client_id} = _assigns) do
    Game.get_client_by_id(game, client_id)
  end

  def me(game, client_id) do
    Game.get_client_by_id(game, client_id)
  end

  def get_scoreboard_players(game) do
    Game.players(game)
  end

  def get_blank_scoreboard_players(game) do
    1..(game.settings.max_players - Game.num_players(game))
  end

  def is_connected?(client) do
    Client.is_connected?(client)
  end

  def show_scoreboard(assigns) do
    assigns.game.state in [:idle, :poll] and me(assigns).answer_state not in [:needed]
  end

  def show_query(assigns) do
    me(assigns).answer_state in [:needed]
  end

  def player_icon(player) do
    if Client.is_connected?(player) do
      case player.answer_state do
        :accepted -> "user-check-solid.svg"
        :needed -> "user-edit-solid.svg"
        :skipped -> "user-times-solid.svg"
        :none -> "user-connected.svg"
      end
    else
      "user-disconnected.svg"
    end
  end

  def player_status(player) do
    if Client.is_connected?(player) do
      "Connected"
    else
      "Disconnected"
    end
  end
end
