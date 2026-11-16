defmodule FitManagerWeb.ErrorJSON do
  @doc """
  Renders error pages in JSON format.
  """
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
