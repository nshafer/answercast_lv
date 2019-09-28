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

  pipeline :game do
    plug :put_layout, {AnswercastWeb.LayoutView, :client}
  end

  scope "/", AnswercastWeb do
    pipe_through :browser

    # Main Splash pages
    live "/", JoinLive
    live "/create", CreateLive

    # Other pages
    get "/about", PageController, :about

    # Debug stuff
    live "/clock", ClockLive
    live "/sandbox", SandboxLive
    live "/sandbox/:name", SandboxLive
  end

  scope "/", AnswercastWeb do
    pipe_through [:browser, :game]

    # Main game interface
    live "/game/:game_id/:type/:client_id", GameLive
  end
end
