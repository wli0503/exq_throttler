defmodule Exq.Test.Middleware.ThrottlerTest do
  use ExUnit.Case

  alias Exq.Middleware.Throttler
  use Timex

  test "get_redix_pid/1 gets redix's pid" do
    assert Throttler.get_redix_pid(%{}) |> is_pid
  end

  test "epoch_seconds/1 returns number of seconds from epoch" do
    assert Timex.DateTime.now |> Timex.format!("%s", :strftime) == Throttler.epoch_seconds
  end

  test "epoch_seconds/1 returns number of seconds plus offset from epoch" do
    assert Timex.DateTime.now
           |> Timex.shift(seconds: 10)
           |> Timex.format!("%s", :strftime) == Throttler.epoch_seconds(10)
  end

  test "should_throttle?/4 returns true if the queue should be throttled" do
    throttle_opts = [period: 0, threshold: 0]
    assert Throttler.should_throttle?(nil, "exq", "testqueue", throttle_opts)
  end

  test "should_throttle?/4 returns false if the queue should not be throttled" do
    throttle_opts = [period: 0, threshold: 100]
    refute Throttler.should_throttle?(nil, "exq", "testqueue", throttle_opts)
  end

  test "get_job_details/1 parses %Pipeline{} and returns a map" do
    job_json = %{queue: "testqueue", class: "testclass", args: ["testarg"]} |> Poison.encode!
    pipeline = %{
      namespace: "exq",
      assigns: %{
        job_json: job_json
      }
    }

    job_details = %{namespace: "exq", queue: "testqueue", class: :testclass, args: ["testarg"]}
    assert job_details == pipeline |> Throttler.get_job_details
  end

  test "get_job_details/1 parses %{}, fills with default value and returns a map" do
    job_details = %{namespace: "exq", queue: "default", class: :"", args: []}
    assert job_details == %{} |> Throttler.get_job_details
  end

  test "do_execute/3 returns pipeline if given nil as throttle_opts" do
    pipeline = %{name: "exq"}
    assert pipeline == Throttler.do_execute(nil, nil, pipeline)
  end

  test "throttle/4 returns pipeline if should_throttle?/4 returns false" do
    pipeline = %{namespace: "exq", assigns: nil}
    assert Throttler.throttle(false, nil, nil, pipeline) == pipeline
  end

  test "throttle/4 throttles the queue, requeues the job and terminates the pipeline" do
    pipeline = %{namespace: "exq", assigns: %{manager: "test_manager", namespace: "test_namespace", queue: "testqueue", job_json: "test_json"}}
    job_details = %{queue: "testqueue", class: "testclass", args: ["testarg"]}
    assert Throttler.throttle(true, [], job_details, pipeline) == (pipeline |> Map.put(:terminated, true))
  end
end
