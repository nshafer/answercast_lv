defmodule AnswercastWeb.ClockLive do
  use Phoenix.LiveView


  def render(assigns) do
    ~L"""
    <div>
      <h2 phx-click="boom">It's <%= Timex.format!(@date, "%r", :strftime) %></h2>
    </div>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  def handle_event("boom", _params, socket) do
    IO.puts "boom"
    {:noreply, socket}
  end

  defp put_date(socket) do
    assign(socket, date: :calendar.local_time())
  end
end
