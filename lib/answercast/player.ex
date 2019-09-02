defmodule Answercast.Player do
  alias __MODULE__

  defstruct(
    name: nil,
    last_update: nil
  )

  def new(name) do
    %Player{name: name, last_update: DateTime.utc_now()}
  end

  def update(player) do
    %Player{player | last_update: DateTime.utc_now()}
  end
end
