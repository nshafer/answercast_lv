defmodule AnswercastWeb.SandboxView do
  use AnswercastWeb, :view

  def upper(name) do
    String.upcase(name)
  end
end
