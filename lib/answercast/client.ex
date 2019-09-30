defmodule Answercast.Client do
  alias __MODULE__

  @valid_answer_states [:none, :needed, :accepted, :skipped]

  defstruct(
    id: nil,
    pid: nil,
    type: nil,
    name: nil,
    answer_state: :none,
    answer: nil,
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

  def refresh(client) do
    %Client{client | last_update: DateTime.utc_now()}
  end

  def update_pid(client, pid) when is_pid(pid) or pid == nil do
    %Client{refresh(client) | pid: pid}
  end

  def update_answer_state(client, answer_state) do
    %Client{refresh(client) | answer_state: answer_state}
  end

  def update_answer(client, answer) do
    %Client{refresh(client) | answer: answer}
  end

  def is_connected?(client) do
    client.pid != nil
  end

  def valid_answer_states() do
    @valid_answer_states
  end
end
