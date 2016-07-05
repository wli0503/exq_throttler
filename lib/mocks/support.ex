defmodule Exq.Test.Mocks.Support do
  defmodule Config do
    def get(:throttler) do
      [
        testqueue: [
          period: 10,
          threshold: 20,
          delay: 30
        ]
      ]
    end

    def get(_) do
      %{}
    end
  end
end
