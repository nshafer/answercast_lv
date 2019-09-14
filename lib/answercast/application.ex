defmodule Answercast.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the process registry
      Answercast.GameRegistry,
      # Start the dynamic game supervisor under which game managers will be started
      Answercast.GameSupervisor,
      # Start the Ecto repository
      Answercast.Repo,
      # Start the endpoint when the application starts
      AnswercastWeb.Endpoint
      # Starts a worker by calling: Answercast.Worker.start_link(arg)
      # {Answercast.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Answercast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AnswercastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
