defmodule Answercast.GameManager do
  use GenServer, restart: :temporary
  require Logger
  alias Answercast.{Game, Player}

  @checkpoint_seconds 10000

  #
  # Client interface
  #

  def start_link(game_id) when is_binary(game_id) do
    game = Game.new(game_id)
    GenServer.start_link(__MODULE__, game, name: via_tuple(game_id))
  end

  defp via_tuple(game_id) do
    Answercast.ProcessRegistry.via_tuple({__MODULE__, game_id})
  end

  def crash(pid) do
    GenServer.cast(pid, :crash)
  end

  def stop(pid, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(pid, reason, timeout)
  end

  # Player functions

  def player_list(pid) do
    GenServer.call(pid, :player_list)
  end

  def player_join(pid, name) do
    GenServer.call(pid, {:player_join, name})
  end

  #
  # Server callbacks
  #

  def init(%{game_id: game_id} = game) do
    Logger.debug("Started GameManager(#{game_id}): #{inspect self()}")
    :timer.send_interval(@checkpoint_seconds, self(), :checkpoint)
    {:ok, game}
  end

  def handle_info(:checkpoint, game) do
    Logger.debug("GameManager.checkpoint #{inspect game}")
    game = game
    |> timeout_players()

    if game.players == [] do
      {:stop, {:shutdown, :no_players}, game}
    else
      {:noreply, game}
    end
  end

  def handle_cast(:crash, game) do
    Logger.debug("Handling :crash")
    if game.game_id == "test", do: raise "crash"
    {:noreply, game}
  end

  # Player callbacks

  def handle_call(:player_list, _from, game) do
    {:reply, game.players, game}
  end

  def handle_call({:player_join, name}, _from, game) do
    Logger.debug("GameManager.player_join #{name}")
    new_player = Player.new(name)
    {:reply, {:ok, new_player}, Game.add_player(game, new_player)}
  end

  #
  # Miscellaneous private functions
  #

  defp timeout_players(game) do
    now = DateTime.utc_now()
    Logger.debug("now: #{now}")

    timeout_players = game.players
    |> Enum.filter(
      fn player ->
        diff = DateTime.diff(now, player.last_update)
        Logger.debug("player #{inspect player} diff #{inspect diff}")
        diff > game.settings.player_timeout
      end)

    Enum.each(timeout_players, fn player -> Logger.info("Game #{game.game_id} Player #{player.name} timeout") end)

    %Game{game | players: game.players -- timeout_players}
  end
end
