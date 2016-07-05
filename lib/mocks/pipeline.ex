defmodule Exq.Test.Mocks.Pipeline do
  def terminate(%{}), do: %{namespace: "exq", assigns: nil, terminated: true}
  def terminate(_), do: false
end
