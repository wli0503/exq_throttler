defmodule Exq.Test.Mocks.Redis do
  defmodule Connection do
    def zcount!(_, "exq:stat:testqueue:processed_with_timestamp", _, _), do: 1
  end
end
