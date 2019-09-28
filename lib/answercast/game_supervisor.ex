defmodule Answercast.GameSupervisor do
  use DynamicSupervisor
  require Logger
  alias Answercast.{GameManager}
  import Answercast.Util

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    Logger.debug("Started Answercast.GameSupervisor(#{inspect(init_arg)}): #{inspect(self())}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def game_exists?(game_id) do
    case GameManager.whereis(game_id) do
      nil -> false
      _ -> true
    end
  end

  def existing_game(game_id) do
    case GameManager.whereis(game_id) do
      nil -> {:error, :game_does_not_exist}
      pid -> {:ok, pid}
    end
  end

  def new_game() do
    game_id = generate_new_game_id()
    case start_child(game_id) do
      {:ok, pid} -> {:ok, pid, game_id}
      {:error, {:already_started, _pid}} -> new_game()
    end
  end

  def new_game(game_id) do
    if game_exists?(game_id) do
      {:error, :game_exists}
    else
      case start_child(game_id) do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, pid}} -> {:ok, pid}
      end
    end
  end

  # def existing_or_new_game(game_id) do
  #   case existing_game(game_id) do
  #     {:ok, pid} -> {:ok, pid}
  #     {:error, :game_does_not_exist} -> new_game(game_id)
  #   end
  # end

  def list_games() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  defp start_child(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {Answercast.GameManager, game_id})
  end
end
