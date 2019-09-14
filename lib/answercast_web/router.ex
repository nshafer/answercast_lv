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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AnswercastWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/clock", ClockLive
    live "/sandbox", SandboxLive
    live "/sandbox/:name", SandboxLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", AnswercastWeb do
  #   pipe_through :api
  # end
end
