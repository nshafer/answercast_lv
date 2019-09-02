defmodule Answercast.GameManagerTest do
  use ExUnit.Case
  alias Answercast.{GameSupervisor,GameManager}

  setup do
    game = GameSupervisor.game_process("TEST")

    on_exit(fn -> GameManager.stop(game) end)

    {:ok, game: game}
  end

  test "Can get current running GameManager" do
    game1 = GameSupervisor.game_process("TST1")
    game2 = GameSupervisor.game_process("TST2")

    assert game1 != game2
    assert game1 == GameSupervisor.game_process("TST1")

    GameManager.stop(game1)
    GameManager.stop(game2)
  end

  test "Player can join game", %{game: game} = _context do
    {:ok, player} = GameManager.player_join(game, "Bob")
    assert player in GameManager.player_list(game)
  end

  test "Game is restarted for each test", %{game: game} = _context do
    assert GameManager.player_list(game) == []
  end
end
