defmodule AnswercastWeb.GameView do
  use AnswercastWeb, :view
  alias Answercast.{Game,GameSettings,Client}

  def get_players(game) do
    Game.clients(game, :player)
  end

  def is_connected?(client) do
    Client.is_connected?(client)
  end
end
