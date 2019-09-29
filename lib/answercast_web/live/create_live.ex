defmodule AnswercastWeb.CreateLive do
  use Phoenix.LiveView, container: {:div, class: "main dialog-container"}
  alias AnswercastWeb.Router.Helpers, as: Routes
  require Logger

  alias Answercast.{GameSupervisor,GameManager}
  import AnswercastWeb.SplashView

  def mount(_session, socket) do
    socket =
      socket
      |> assign(:client_type, "player")
      |> assign(:name, "")

    {:ok, socket}
  end

  def render(assigns) do
    AnswercastWeb.SplashView.render("create.html", assigns)
  end

  def handle_event("validate", params, socket) do
    socket =
      socket
      |> assign(:client_type, params["client_type"] || "")
      |> assign(:name, params["name"] || "")

    {:noreply, socket}
  end

  def handle_event("create_game", params, socket) do
    if valid_params?(params) do
      {:ok, mgr, game_id} = GameSupervisor.new_game()
      Logger.debug("Created new game: #{game_id}")

      client_type = parse_client_type(params["client_type"])
      {:ok, client} = GameManager.add_client(mgr, client_type, params["name"])
      Logger.debug("Joined to game: #{client.id}")

      url = Routes.live_path(socket, AnswercastWeb.GameLive, game_id, client.id)
      Logger.debug("Redirecting to #{url}")
      {:noreply, redirect(socket, to: url)}
    else
      {:noreply, socket}
    end
  end

  defp valid_params?(params) do
    cond do
      params["client_type"] == "viewer" and params["name"] == nil -> true
      params["client_type"] == "player" and valid_name?(params["name"]) -> true
      true -> false
    end
  end

  defp parse_client_type("player"), do: :player
  defp parse_client_type("viewer"), do: :viewer
end
