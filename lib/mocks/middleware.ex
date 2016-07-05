defmodule Exq.Test.Mocks.Middleware do
  defmodule Job do
    def remove_job_from_backup(_), do: nil
  end
end
