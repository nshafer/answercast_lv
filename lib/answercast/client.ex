defmodule Answercast.Client do
  alias __MODULE__

  defstruct(
    id: nil,
    pid: nil,
    type: nil,
    name: nil,
    last_update: nil
  )

  def new(id, type, name \\ nil) when type in [:player, :viewer] do
    %Client{
      id: id,
      type: type,
      name: name,
      last_update: DateTime.utc_now(),
    }
  end

  def update(client) do
    %Client{client | last_update: DateTime.utc_now()}
  end

  def update_pid(client, pid) do
    update(client)
    %Client{client | pid: pid}
  end
end
