defmodule AnswercastWeb.PageController do
  use AnswercastWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
