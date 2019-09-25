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
    plug :put_layout, {AnswercastWeb.LayoutView, :game}
  end

  scope "/", AnswercastWeb do
    pipe_through :browser

    get "/about", AboutController, :index

    live "/clock", ClockLive
    live "/sandbox", SandboxLive
    live "/sandbox/:name", SandboxLive
  end

  scope "/", AnswercastWeb do
    pipe_through [:browser, :game]

    get "/", SplashController, :index
  end
end
