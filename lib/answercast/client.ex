defmodule Answercast.Client do
  alias __MODULE__

  defstruct(
    id: nil,
    pid: nil,
    type: nil,
    name: nil,
    last_update: nil
  )

  def new(id, pid, type, name \\ nil) when type in [:player, :viewer] do
    %Client{id: id, pid: pid, type: type, name: name, last_update: DateTime.utc_now()}
  end

  def update(client) do
    %Client{client | last_update: DateTime.utc_now()}
  end
end
