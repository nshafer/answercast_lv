defmodule Answercast.GameManager do
  use GenServer, restart: :transient
  require Logger

  alias Answercast.{GameRegistry, Game, Client, GameSettings}

  #
  # Client interface
  #

  def start_link(game_id) when is_binary(game_id) do
    game_id = Game.normalize_game_id(game_id)
    game = Game.new(game_id)
    GenServer.start_link(__MODULE__, game, name: via_tuple(game_id))
  end

  def via_tuple(game_id) do
    game_id
    |> Game.normalize_game_id()
    |> GameRegistry.via_tuple()
  end

  def whereis(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
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

  #
  # Game functions
  #

  def players(pid) do
    GenServer.call(pid, {:clients, :player})
  end

  def viewers(pid) do
    GenServer.call(pid, {:clients, :viewer})
  end

  def clients(pid) do
    GenServer.call(pid, :clients)
  end

  def add_client(pid, type, name) when type in [:player, :viewer] do
    GenServer.call(pid, {:add_client, type, name})
  end

  def add_player(pid, name) do
    add_client(pid, :player, name)
  end

  def add_viewer(pid) do
    add_client(pid, :viewer, nil)
  end

  def get_client_by_id(pid, client_id) do
    GenServer.call(pid, {:get_client_by_id, client_id})
  end

  def get_client_by_name(_pid, name) when name == nil, do: nil
  def get_client_by_name(pid, name) when is_binary(name) do
    GenServer.call(pid, {:get_client_by_name, name})
  end

  def name_in_use?(pid, name) do
    case get_client_by_name(pid, name) do
      nil -> false
      _client -> true
    end
  end

  def connect(pid, client_id) do
    GenServer.call(pid, {:connect, client_id})
  end

  # Settings

  def settings(pid) do
    GenServer.call(pid, :get_settings)
  end

  def change_settings(pid, %GameSettings{} = settings) do
    GenServer.call(pid, {:change_settings, settings})
  end

  #
  # Game callbacks
  #

  def handle_call({:clients, type}, _from, game) do
    {:reply, Game.clients(game, type), game}
  end

  def handle_call(:clients, _from, game) do
    {:reply, Game.clients(game), game}
  end

  def handle_call({:add_client, type, name}, _from, game) do
    Logger.debug("GameManager.add_client #{type} #{name}")
    {new_client, new_game} = Game.add_client(game, type, name)
    broadcast(new_game, {:join, type, new_client, new_game})
    {:reply, {:ok, new_client}, new_game}
  end

  def handle_call(:get_settings, _from, game) do
    {:reply, game.settings, game}
  end

  def handle_call({:change_settings, settings}, _from, game) do
    Logger.debug("GameManager.change_settings #{inspect settings}")
    game = Game.change_settings(game, settings)
    broadcast(game, {:settings_changed, settings})
    {:reply, :ok, game}
  end

  def handle_call({:get_client_by_id, client_id}, _from, game) do
    {:reply, Game.get_client_by_id(game, client_id), game}
  end

  def handle_call({:get_client_by_name, name}, _from, game) do
    {:reply, Game.get_client_by_name(game, name), game}
  end

  def handle_call({:connect, client_id}, {pid, _tag}, game) do
    case Game.get_client_by_id(game, client_id) do
      nil -> {:reply, {:error, :client_not_found}, game}
      client ->
         new_client = Client.update_pid(client, pid)
         new_game = Game.update_client(game, new_client)
         Logger.debug("GameManager connect client: #{inspect new_client} game: #{inspect game}}")
         broadcast(new_game, {:connect, new_client, new_game})
         {:reply, {:ok, new_client, new_game}, new_game}
    end
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

  @checkpoint_seconds 10
  @shutdown_empty_games true
  @shutdown_grace_period 60

  def init(%{id: game_id} = game) do
    Logger.debug("Started GameManager(#{game_id}): #{inspect(self())}")
    :timer.send_interval(@checkpoint_seconds * 1000, self(), :checkpoint)
    {:ok, game}
  end

  def handle_info(:checkpoint, game) do
#    Logger.debug("GameManager.checkpoint #{inspect game}")
    game =
      game
      |> timeout_clients()

    if game_should_shutdown(game) do
      Logger.debug("Stopping GameManager(#{game.id}): #{inspect(self())}")
      {:stop, {:shutdown, :no_clients}, game}
    else
      {:noreply, game}
    end
  end

  #
  # Broadcasting
  #

  defp broadcast_to_clients(clients, message) do
    clients
    |> Stream.filter(fn client -> client.pid != nil end)
    |> Enum.each(fn client -> send(client.pid, message) end)
  end

  def broadcast(game, message) do
    broadcast_to_clients(Game.clients(game), message)
  end

  def broadcast(game, type, message) do
    broadcast_to_clients(Game.clients(game, type), message)
  end

  def broadcast_players(game, message) do
    broadcast(game, :players, message)
  end

  def broadcast_viewers(game, message) do
    broadcast(game, :viewers, message)
  end

  #
  # Miscellaneous private functions
  #

  defp game_should_shutdown(game) do
    now = DateTime.utc_now()

    game_running_for = DateTime.diff(now, game.started)
    game_idle_for = DateTime.diff(now, game.last_update)

    @shutdown_empty_games
      and game.clients == []
      and game_running_for > @shutdown_grace_period
      and game_idle_for > @shutdown_grace_period
  end

  defp timeout_clients(game) do
    now = DateTime.utc_now()

    Game.clients(game)
      |> Stream.filter(fn client -> DateTime.diff(now, client.last_update) > game.settings.client_timeout end)
      |> Stream.each(fn client ->
        Logger.info("Client timeout Game:#{game.id} Client:#{client.id} type:#{client.type} name:#{client.name}")
      end)
      |> Enum.reduce(game, fn client, game -> Game.remove_client(game, client) end)
  end
end
