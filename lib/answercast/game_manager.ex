defmodule Answercast.GameManager do
  use GenServer, restart: :transient
  require Logger

  alias Answercast.{GameRegistry, Game, Client, GameSettings}

  @valid_game_states Game.valid_states()
#  @valid_answer_states Client.valid_answer_states()

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

  def remove_client(pid, client) do
    GenServer.call(pid, {:remove_client, client})
  end

  def remove_player(pid, player) do
    remove_client(pid, player)
  end

  def remove_viewer(pid, viewer) do
    remove_client(pid, viewer)
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

  def disconnect(pid, client) do
    GenServer.call(pid, {:disconnect, client})
  end

  def ping(pid, client) do
    GenServer.call(pid, {:ping, client})
  end

  def change_state(pid, state) when state in @valid_game_states do
    GenServer.call(pid, {:change_state, state})
  end

  def submit_answer(pid, %Client{} = client, answer) when is_binary(answer) do
    GenServer.call(pid, {:submit_answer, client, answer})
  end

  def skip_answer(pid, %Client{} = client) do
    GenServer.call(pid, {:skip_answer, client})
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
    Logger.debug("GameManager [#{game.id}] add_client type:#{type} name:#{name}")
    {new_client, new_game} = Game.add_client(game, type, name)
    broadcast(new_game, {:join, new_client, new_game})
    {:reply, {:ok, new_client, new_game}, new_game}
  end

  def handle_call({:remove_client, client}, _from, game) do
    Logger.debug("GameManager [#{game.id}] remove_client id: #{client.id} type:#{client.type} name:#{client.name}")
    new_game = Game.remove_client(game, client)
    broadcast(game, {:leave, client, new_game})  # broadcast to the original game so the client gets it as well
    Logger.debug("GameManager [#{game.id}] clients now: #{inspect Game.clients(new_game)}")
    {:reply, {:ok, new_game}, new_game}
  end

  def handle_call(:get_settings, _from, game) do
    {:reply, game.settings, game}
  end

  def handle_call({:change_settings, settings}, _from, game) do
    Logger.debug("GameManager [#{game.id}] change_settings settings:#{inspect settings}")
    new_game = Game.change_settings(game, settings)
    broadcast(game, {:settings_changed, settings, new_game})
    {:reply, :ok, new_game}
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
         Logger.debug("GameManager [#{game.id}] connect client: #{new_client.id} name: #{client.name}")
         broadcast(new_game, {:connect, new_client, new_game})
         {:reply, {:ok, new_client, new_game}, new_game}
    end
  end

  def handle_call({:disconnect, client}, _from, game) do
    case Game.get_client_by_id(game, client.id) do
      nil -> {:reply, {:error, :client_not_found}, game}
      client ->
        new_client = Client.update_pid(client, nil)
        new_game = Game.update_client(game, new_client)
        Logger.debug("GameManager [#{game.id}] disconnect client: #{new_client.id} name: #{client.name}")
        broadcast(new_game, {:disconnect, new_client, new_game})
        {:reply, {:ok, new_client, new_game}, new_game}
    end
  end

  def handle_call({:ping, client}, _from, game) do
    Logger.debug("GameManager [#{game.id} ping client: #{client.id} name: #{client.name}")
    with real_client when real_client != nil <- Game.get_client_by_id(game, client.id),
         new_client <- Client.refresh(real_client),
         new_game = Game.update_client(game, new_client) do
      {:reply, {:ok, new_client, new_game}, new_game}
    else
      nil -> {:reply, {:error, :client_not_connected}, game}
      error -> {:reply, {:error, error}, game}
    end
  end

  def handle_call({:change_state, state}, _from, game) do
    Logger.debug("GameManager [#{game.id} change_state from: #{game.state} to #{state}")
    if state != game.state do
      new_game = change_game_state(game, state)
      {:reply, {:ok, new_game}, new_game}
    else
      {:reply, {:error, :already_in_state}, game}
    end
  end

  def handle_call({:submit_answer, client, answer}, _from, game) do
    Logger.debug("GameManager [#{game.id} submit_answer client: #{client.id} answer: #{answer}")
    new_client =
      client
      |> Client.update_answer(answer)
      |> Client.update_answer_state(:accepted)

    new_game = Game.update_client(game, new_client)

    broadcast(new_game, {:answer_submitted, new_client, new_game})

    if all_answers_submitted(new_game) do
      new_game = change_game_state(new_game, :results)
      {:reply, {:ok, new_game}, new_game}
    else
      {:reply, {:ok, new_game}, new_game}
    end
  end

  def handle_call({:skip_answer, client}, _from, game) do
    Logger.debug("GameManager [#{game.id} skip_answer client: #{client.id}")
    new_client = Client.update_answer_state(client, :skipped)
    new_game = Game.update_client(game, new_client)

    broadcast(new_game, {:answer_skipped, new_client, new_game})

    if all_answers_submitted(new_game) do
      new_game = change_game_state(new_game, :results)
      {:reply, {:ok, new_game}, new_game}
    else
      {:reply, {:ok, new_game}, new_game}
    end
  end

  #
  # Server callbacks
  #

  def handle_call(:crash, from, game) do
    Logger.debug("GameManager [#{game.id}] crash")
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
  # Game Management functions
  #

  defp change_game_state(game, new_state) do
    Logger.debug("GameManager [#{game.id}] change_game_state #{game.state} -> #{new_state} ")

    if new_state != game.state do
      new_game =
        game
        |> Game.change_state(new_state)
        |> game_state_changed(game.state, new_state)
      broadcast(game, {:change_state, game.state, new_state, new_game})
      new_game
    else
      game
    end
  end

  # The first round begins
  defp game_state_changed(game, :idle, :poll) do
    Logger.debug("GameManager [#{game.id}] game_state_changed :idle -> :poll")
    game
    |> reset_player_answers(:needed)
  end

  # We want to look at the answers
  defp game_state_changed(game, :idle, :results) do
    Logger.debug("GameManager [#{game.id}] game_state_changed :idle -> :poll")
  end

  # A round was canceled
  defp game_state_changed(game, :poll, :idle) do
    Logger.debug("GameManager [#{game.id}] game_state_changed :poll -> :idle")
    game
    |> reset_player_answers()
  end

  # A round was finished
  defp game_state_changed(game, :poll, :results) do
    Logger.debug("GameManager [#{game.id}] game_state_changed :poll -> :results")
    game
    |> gather_answers()
    |> reset_player_answers()
  end

  # A new round is starting
  defp game_state_changed(game, :results, :poll) do
    Logger.debug("GameManager [#{game.id}] game_state_changed :idle -> :poll")
    game
    |> reset_player_answers(:needed)
  end

  defp reset_player_answers(game, answer_state \\ :none, answer \\ nil) do
    Game.players(game)
    |> Stream.map(fn player -> Client.update_answer_state(player, answer_state) end)
    |> Stream.map(fn player -> Client.update_answer(player, answer) end)
    |> Enum.reduce(game, fn player, game -> Game.update_player(game, player) end)
  end

  defp gather_answers(game) do
    Logger.debug("GameManager [#{game.id}] gather_answers")
    answers =
      Game.players(game)
      |> Stream.filter(fn player -> player.answer_state in [:accepted] end)
      |> Stream.map(fn player -> player.answer end)
      |> Enum.shuffle()
    Logger.debug("GameManager [#{game.id}] answers now: #{inspect answers}")
    Game.update_answers(game, answers)
  end

  defp all_answers_submitted(game) do
    Game.players(game)
    |> Enum.all?(fn player -> player.answer_state in [:accepted, :skipped] end)
  end

  #
  # Miscellaneous private functions
  #

  defp game_should_shutdown(game) do
    now = DateTime.utc_now()

    game_running_for = DateTime.diff(now, game.started)
    game_idle_for = DateTime.diff(now, game.last_update)

    @shutdown_empty_games
      and Game.num_clients(game) == 0
      and game_running_for > @shutdown_grace_period
      and game_idle_for > @shutdown_grace_period
  end

  defp timeout_clients(game) do
    now = DateTime.utc_now()

    Game.clients(game)
      |> Stream.filter(fn client -> DateTime.diff(now, client.last_update) > game.settings.client_timeout end)
      |> Enum.reduce(game, fn client, game ->
        Logger.info("Client timeout Game:#{game.id} Client:#{client.id} type:#{client.type} name:#{client.name}")
        new_game = Game.remove_client(game, client)
        broadcast(game, {:leave, client, new_game})  # broadcast to the original game so the client gets it as well
        new_game
      end)
  end
end
