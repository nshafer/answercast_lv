defmodule AnswercastWeb.LayoutView do
  use AnswercastWeb, :view

  def year() do
    Date.utc_today().year
  end
end
