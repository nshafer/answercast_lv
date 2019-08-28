defmodule Answercast.Repo do
  use Ecto.Repo,
    otp_app: :answercast,
    adapter: Ecto.Adapters.Postgres
end
