defmodule Answercast.ProcessRegistry do
  require Logger

  def start_link do
    {:ok, reg} = Registry.start_link(keys: :unique, name: __MODULE__)
    Logger.debug("Started Answercast.ProcessRegistry: #{inspect reg}")
    {:ok, reg}
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
