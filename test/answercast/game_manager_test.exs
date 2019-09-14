defmodule Answercast.GameManagerTest do
  use ExUnit.Case
  alias Answercast.{GameSupervisor, GameManager}

  setup do
    {:ok, game} = GameSupervisor.new_game("TEST")

    on_exit(fn -> GameManager.stop(game) end)

    {:ok, game: game}
  end

  test "Can get current running GameManager" do
    {:ok, game1} = GameSupervisor.new_game("TST1")
    {:ok, game2} = GameSupervisor.new_game("TST2")

    assert game1 != game2
    assert game1 == GameSupervisor.existing_game!("TST1")

    GameManager.stop(game1)
    GameManager.stop(game2)
  end

  test "Player can join game", %{game: game} = _context do
    {:ok, player} = GameManager.join_player(game, "Bob")
    assert player in GameManager.players(game)
    assert player in GameManager.clients(game)
  end

  test "Viewer can join game", %{game: game} = _context do
    {:ok, viewer} = GameManager.join_viewer(game)
    assert viewer in GameManager.viewers(game)
    assert viewer in GameManager.clients(game)
  end

  test "Game is restarted for each test", %{game: game} = _context do
    assert GameManager.clients(game) == []
  end

  test "Game is in the list of games", %{game: game} = _context do
    assert game in GameSupervisor.list_games()
  end
end
