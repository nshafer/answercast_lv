defmodule AnswercastWeb.JoinLive do
  use Phoenix.LiveView, container: {:div, class: "main join-stack-container"}
  alias AnswercastWeb.Router.Helpers, as: Routes
  require Logger

  alias Answercast.{GameSupervisor,GameManager}
  import AnswercastWeb.SplashView

  @stack_switch_delay 710

  def render(assigns) do
    AnswercastWeb.SplashView.render("join.html", assigns)
  end

  def mount(_session, socket) do
    socket =
      socket
      |> assign(:mode, :player)
      |> assign(:player_stack_classes, "active")
      |> assign(:viewer_stack_classes, "")
      |> assign(:game_id, "")
      |> assign(:name, "")
    {:ok, socket}
  end

  def handle_event("validate", params, socket) do
    socket =
      socket
      |> assign(:game_id, params["game_id"] || "")
      |> assign(:name, params["name"] || "")
    {:noreply, socket}
  end

  def handle_event("join_player", %{"game_id" => game_id, "name" => name}, socket) do
    if valid_game_id?(game_id) and valid_name?(game_id, name) do
      {:ok, mgr} = GameSupervisor.existing_game(game_id)
      {:ok, player} = GameManager.add_player(mgr, name)
      url = Routes.live_path(socket, AnswercastWeb.GameLive, :player, game_id, player.id)
      {:noreply, live_redirect(socket, to: url)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("join_viewer", %{"game_id" => game_id}, socket) do
    if valid_game_id?(game_id) do
      {:ok, mgr} = GameSupervisor.existing_game(game_id)
      {:ok, viewer} = GameManager.add_viewer(mgr)
      url = Routes.live_path(socket, AnswercastWeb.GameLive, :viewer, game_id, viewer.id)
      {:noreply, live_redirect(socket, to: url)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change_mode", %{"mode" => "player"}, socket) do
    socket =
      socket
      |> assign(:player_stack_classes, "activating")
      |> assign(:viewer_stack_classes, "active deactivating")
    Process.send_after(self(), {:finish_activating, :player}, @stack_switch_delay)
    {:noreply, socket}
  end

  def handle_event("change_mode", %{"mode" => "viewer"}, socket) do
    socket =
      socket
      |> assign(:player_stack_classes, "active deactivating")
      |> assign(:viewer_stack_classes, "activating")
    Process.send_after(self(), {:finish_activating, :viewer}, @stack_switch_delay)
    {:noreply, socket}
  end

  def handle_info({:finish_activating, :player}, socket) do
    socket =
      socket
      |> assign(:mode, :player)
      |> assign(:player_stack_classes, "active")
      |> assign(:viewer_stack_classes, "")
    {:noreply, socket}
  end

  def handle_info({:finish_activating, :viewer}, socket) do
    socket =
      socket
      |> assign(:mode, :viewer)
      |> assign(:player_stack_classes, "")
      |> assign(:viewer_stack_classes, "active")
    {:noreply, socket}
  end

end
