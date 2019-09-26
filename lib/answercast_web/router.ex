defmodule AnswercastWeb.Router do
  use AnswercastWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AnswercastWeb do
    pipe_through :browser

    live "/", JoinLive

    get "/about", PageController, :about

    live "/clock", ClockLive
    live "/sandbox", SandboxLive
    live "/sandbox/:name", SandboxLive
  end
end
