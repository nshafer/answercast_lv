defmodule AnswercastWeb.GameLive do
  use Phoenix.LiveView, container: {:div, class: "gameboard"}
  require Logger

  alias Answercast.{GameSupervisor,GameManager}
  import AnswercastWeb.GameView, only: [me: 1]

  @ping_seconds 30

  def mount(_session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"game_id" => game_id, "client_id" => client_id} = _params, _url, socket) do
    with {:ok, mgr} <- GameSupervisor.existing_game(game_id),
         {:ok, client, game} <- GameManager.connect(mgr, client_id) do
      :timer.send_interval(@ping_seconds * 1000, self(), :ping)
      {:noreply, assign(socket, game: game, client_id: client_id, type: client.type)}
    else
      _ -> {:noreply, redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    case assigns.type do
      :player -> AnswercastWeb.GameView.render("player.html", assigns)
      :viewer -> AnswercastWeb.GameView.render("viewer.html", assigns)
    end
  end

  def handle_info({:join, _client, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:leave, client, game}, socket) do
    if client.id == me(socket).id do
      {:noreply, redirect(socket, to: "/")}
    else
      {:noreply, assign(socket, game: game)}
    end
  end

  def handle_info({:connect, _client, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:disconnect, _client, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(:ping, socket) do
    case GameSupervisor.existing_game(socket.assigns.game.id) do
      {:ok, mgr} ->
        GameManager.ping(mgr, me(socket))
        {:noreply, socket}
      {:err, error} ->
        Logger.error("Could not find GameManager during ping: #{inspect error}")
        {:noreply, redirect(socket, to: "/")}
    end
  end

  def handle_info({:change_state, old_state, new_state, game}, socket) do
    Logger.debug("Changed state from #{old_state} to #{new_state}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(message, socket) do
    Logger.warn("Unhandled message: #{inspect message}")
    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.debug("terminate #{inspect reason} #{inspect socket.assigns}")
    with {:ok, game} <- Map.fetch(socket.assigns, :game),
         {:ok, mgr} <- GameSupervisor.existing_game(game.id),
         {:ok, _client, _game} <- GameManager.disconnect(mgr, me(socket)) do
    else
      err -> Logger.warn("Could not disconnect: #{inspect err}")
      :ok
    end
  end
end
