defmodule AnswercastWeb.GameLive do
  use Phoenix.LiveView, container: {:div, class: "main"}
  require Logger

  alias Answercast.{GameSupervisor,GameManager}

  def render(assigns) do
    AnswercastWeb.GameView.render("game.html", assigns)
  end

  def mount(_session, socket) do
    socket =
      socket
      |> assign(status: :idle)
    {:ok, socket}
  end

  def handle_params(%{"type" => type, "game_id" => game_id, "client_id" => client_id} = params, _url, socket) do
    Logger.debug("handle_params: #{inspect params}")
    with {:ok, mgr} <- GameSupervisor.existing_game(game_id),
         {:ok, client, game} <- GameManager.connect(mgr, client_id) do
      {:noreply, assign(socket, type: type, client: client, game: game)}
    else
      _ -> {:noreply, live_redirect(socket, to: "/")}
    end
  end

  def handle_info({:join, type, client, game}, socket) do
#    Logger.debug("Got :join type:#{type} client:#{inspect client} game: #{inspect game}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:connect, client, game}, socket) do
#    Logger.debug("Got :connect client:#{inspect client} game: #{inspect game}")
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(message, socket) do
    Logger.warn("Unhandled message: #{inspect message}")
    {:noreply, socket}
  end
end
