defmodule AnswercastWeb.GameLive do
  use Phoenix.LiveView, container: {:div, class: "game"}
  require Logger

  alias Answercast.{GameSupervisor,GameManager}

  @ping_seconds 30

  def render(assigns) do
    AnswercastWeb.GameView.render("game.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"type" => type, "game_id" => game_id, "client_id" => client_id} = params, _url, socket) do
    with {:ok, mgr} <- GameSupervisor.existing_game(game_id),
         {:ok, me, game} <- GameManager.connect(mgr, client_id) do
      Logger.debug("Connected me:#{inspect me}")
      :timer.send_interval(@ping_seconds * 1000, self(), {:ping, game, me})
      {:noreply, assign(socket, type: type, me: me, game: game)}
    else
      _ -> {:noreply, redirect(socket, to: "/")}
    end
  end

  def handle_info({:join, _type, _client, game}, socket) do
#    Logger.debug("Got :join type:#{type} client:#{inspect client} game: #{inspect game}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:leave, type, client, game}, socket) do
#    Logger.debug("Got :leave type:#{type} client:#{inspect client} game: #{inspect game}")
    if client.id == my_client_id(socket) do
      {:noreply, redirect(socket, to: "/")}
    else
      {:noreply, assign(socket, game: game)}
    end
  end

  def handle_info({:connect, _client, game}, socket) do
#    Logger.debug("Got :connect client:#{inspect client} game: #{inspect game}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:disconnect, _client, game}, socket) do
#    Logger.debug("Got :disconnect client:#{inspect client} game: #{inspect game}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:ping, game, me}, socket) do
#    Logger.debug("Got :ping #{game.id} #{me.id}")
    case GameSupervisor.existing_game(game.id) do
      {:ok, mgr} ->
        GameManager.ping(mgr, me)
        {:noreply, socket}
      _ -> {:noreply, redirect(socket, to: "/")}
    end

  end

  def handle_info(message, socket) do
    Logger.warn("Unhandled message: #{inspect message}")
    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.debug("terminate #{inspect reason} #{inspect socket.assigns}")
    with {:ok, game} <- Map.fetch(socket.assigns, :game),
         {:ok, me} <- Map.fetch(socket.assigns, :me),
         {:ok, mgr} <- GameSupervisor.existing_game(game.id),
         {:ok, _client, _game} <- GameManager.disconnect(mgr, me) do
    else
      err -> Logger.warn("Could not disconnect: #{inspect err}")
      :ok
    end
  end

  defp my_client_id(socket) do
    case socket.assigns[:me] do
      nil -> nil
      me -> me.id
    end
  end
end
