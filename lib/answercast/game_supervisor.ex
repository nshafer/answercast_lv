defmodule Answercast.GameSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    Logger.debug("Started Answercast.GameSupervisor(#{inspect init_arg}): #{inspect self()}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def game_process(game_id) do
    case start_child(game_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {Answercast.GameManager, game_id})
  end

end
