defmodule AnswercastWeb.SandboxLive do
  use Phoenix.LiveView, container: {:div, class: "main"}
  alias AnswercastWeb.Router.Helpers, as: Routes
  require Logger

  def render(assigns) do
    AnswercastWeb.SandboxView.render("form.html", assigns)
  end

  def mount(session, socket) do
    Logger.debug("mount: #{inspect session} #{inspect socket}")

    {:ok, assign(socket, :name, nil)}
  end

  def handle_params(params, url, socket) do
    Logger.debug("handle_params: #{inspect params}, #{url}")
    {:noreply, socket |> assign(name: Map.get(params, "name"))}
  end

  def handle_event("update", %{"name" => name}, socket) do
    {:noreply, assign(socket, :name, name)}
  end

  def handle_event("save", %{"name" => name}, socket) do
    IO.puts("save #{name}")
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, AnswercastWeb.SandboxLive, name))}
  end

  def handle_event(event, params, socket) do
    IO.puts("Unhandled event: #{inspect(event)}(#{inspect(params)})")
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.puts("SandboxLive info #{inspect(msg)} #{inspect(socket)}")
    {:noreply, socket}
  end
end
