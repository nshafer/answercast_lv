defmodule AnswercastWeb.PageController do
  use AnswercastWeb, :controller

  def about(conn, _params) do
    IO.puts("layout: #{inspect layout(conn)} formats: #{inspect layout_formats(conn)}")
    render(conn, "about.html")
  end
end
