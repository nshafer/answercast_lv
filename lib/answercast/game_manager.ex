defmodule Answercast.GameManager do
  use GenServer, restart: :transient
  alias Answercast.{GameRegistry, Game}
  require Logger

  #
  # Client interface
  #

  def start_link(game_id) when is_binary(game_id) do
    game_id = normalize_game_id(game_id)
    game = Game.new(game_id)
    GenServer.start_link(__MODULE__, game, name: via_tuple(game_id))
  end

  def via_tuple(game_id) do
    game_id
    |> normalize_game_id()
    |> GameRegistry.via_tuple()
  end

  def whereis(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  def normalize_game_id(game_id) do
    game_id
    |> String.slice(0..3)
    |> String.upcase()
  end

  def stop(pid, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(pid, reason, timeout)
  end

  def crash(pid) do
    GenServer.call(pid, :crash)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Player functions

  def players(pid) do
    GenServer.call(pid, {:list, :player})
  end

  def viewers(pid) do
    GenServer.call(pid, {:list, :viewer})
  end

  def clients(pid) do
    GenServer.call(pid, :list)
  end

  def join_player(pid, name) do
    GenServer.call(pid, {:join, :player, name})
  end

  def join_viewer(pid) do
    GenServer.call(pid, {:join, :viewer, nil})
  end

  # Player callbacks

  def handle_call({:list, type}, _from, game) do
    {:reply, Game.clients(game, type), game}
  end

  def handle_call(:list, _from, game) do
    {:reply, Game.clients(game), game}
  end

  def handle_call({:join, type, name}, {pid, _tag}, game) do
    Logger.debug("GameManager.player_join #{name}")
    {new_client, game} = Game.add_client(game, pid, type, name)
    broadcast(game, {:join, new_client})
    {:reply, {:ok, new_client}, game}
  end

  #
  # Server callbacks
  #

  def handle_call(:crash, from, game) do
    Logger.debug("Handling :crash")
    if game.id == "TEST" do
      GenServer.reply(from, :ok)
      raise("crash")
    end
    {:reply, :ok, game}
  end

  def handle_call(:get_state, _from, game)do
    {:reply, game, game}
  end

  @checkpoint_seconds 10000
  @shutdown_empty_games false

  def init(%{id: game_id} = game) do
    Logger.debug("Started GameManager(#{game_id}): #{inspect(self())}")
    :timer.send_interval(@checkpoint_seconds, self(), :checkpoint)
    {:ok, game}
  end

  def handle_info(:checkpoint, game) do
    # Logger.debug("GameManager.checkpoint #{inspect game}")
    game =
      game
      |> timeout_clients()

    if @shutdown_empty_games and game.clients == [] do
      Logger.debug("Stopping GameManager(#{game.id}): #{inspect(self())}")
      {:stop, {:shutdown, :no_clients}, game}
    else
      {:noreply, game}
    end
  end

  #
  # Miscellaneous private functions
  #

  defp broadcast_to_clients(clients, message) do
    clients
    |> Enum.each(fn client ->
      send(client.pid, message)
    end)
  end

  defp broadcast(game, message) do
    broadcast_to_clients(game.clients, message)
  end

  defp broadcast(game, type, message) do
    broadcast_to_clients(Game.clients(game, type), message)
  end

  defp timeout_clients(game) do
    now = DateTime.utc_now()

    timeout_clients =
      game.clients
      |> Enum.filter(fn client ->
        DateTime.diff(now, client.last_update) > game.settings.client_timeout
      end)

    Enum.each(timeout_clients, fn client ->
      Logger.info("Game #{game.id} Client id:#{client.id} type:#{client.type} name:#{client.name} timeout")
    end)

    %Game{game | clients: game.clients -- timeout_clients}
  end
end
