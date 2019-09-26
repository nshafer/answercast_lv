defmodule AnswercastWeb.JoinLive do
  use Phoenix.LiveView, container: {:div, class: "main join-stack-container"}
  import AnswercastWeb.Util

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
    if valid_game_id(game_id) and valid_name(name) do
      IO.puts "join_player game: #{game_id} name: #{name}"
    end
    {:noreply, socket}
  end

  def handle_event("join_viewer", %{"game_id" => game_id}, socket) do
    if valid_game_id(game_id) do
      IO.puts "join_viewer game: #{game_id}"
    end
    {:noreply, socket}
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
