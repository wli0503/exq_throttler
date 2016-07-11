defmodule Exq.Test.Mocks.Manager do
  defmodule Server do
    def job_terminated(_, _, _, _) do
      true
    end
  end
end
