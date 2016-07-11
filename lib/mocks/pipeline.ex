defmodule Exq.Test.Mocks.Pipeline do
  def terminate(%{assigns: assigns}), do: %{namespace: "exq", assigns: assigns, terminated: true}
  def terminate(_), do: false
end
