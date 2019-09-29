defmodule AnswercastWeb.GameLive do
  use Phoenix.LiveView, container: {:div, class: "gameboard"}
  require Logger

  alias Answercast.{GameSupervisor,GameManager}

  @ping_seconds 30

  def mount(_session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"game_id" => game_id, "client_id" => client_id} = params, _url, socket) do
    with {:ok, mgr} <- GameSupervisor.existing_game(game_id),
         {:ok, me, game} <- GameManager.connect(mgr, client_id) do
      :timer.send_interval(@ping_seconds * 1000, self(), {:ping, game, me})
      {:noreply, assign(socket, me: me, game: game)}
    else
      _ -> {:noreply, redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    case assigns.me.type do
      :player -> AnswercastWeb.GameView.render("player.html", assigns)
      :viewer -> AnswercastWeb.GameView.render("viewer.html", assigns)
    end
  end

  def handle_info({:join, _client, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:leave, client, game}, socket) do
    if client.id == my_client_id(socket) do
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

  def handle_info({:ping, game, me}, socket) do
    case GameSupervisor.existing_game(game.id) do
      {:ok, mgr} ->
        GameManager.ping(mgr, me)
        {:noreply, socket}
      {:err, error} ->
        Logger.error("Could not find GameManager during ping: #{inspect error}")
        {:noreply, redirect(socket, to: "/")}
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
