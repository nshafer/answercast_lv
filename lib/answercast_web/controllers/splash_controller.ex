defmodule AnswercastWeb.SplashController do
  use AnswercastWeb, :controller

  def index(conn, _params) do
    IO.puts("layout: #{inspect layout(conn)} formats: #{inspect layout_formats(conn)}")
    render(conn, "index.html")
  end
end
