defmodule Exq.Middleware.Throttler do
  use Timex
  @behaviour Exq.Middleware.Behaviour
  @mock Application.get_env(:exq_throttler, :mock, %{})

  @exq_middleware Map.get(@mock, :middleware, Exq.Middleware)
  @exq Map.get(@mock, :exq, Exq)
  @pipeline Map.get(@mock, :pipeline, Exq.Middleware.Pipeline)
  @redis Map.get(@mock, :redis, Exq.Redis)
  @config Map.get(@mock, :config, Exq.Support.Config)
  @manager Map.get(@mock, :manager, Exq.Manager.Server)

  def before_work(pipeline), do: pipeline |> get_job_details |> execute(pipeline)
  def after_processed_work(pipeline) do
    job_details_map = pipeline |> get_job_details
    %{queue: queue, namespace: namespace} = job_details_map
    queue
    |> String.to_atom
    |> get_throttler_opts
    |> record_throttled(get_redis_pid, namespace, queue)
    pipeline
  end
  def after_failed_work(pipeline), do: pipeline

  def get_redis_pid do
    {:ok, pid} = Redix.start_link
    pid
  end

  def get_throttler_opts(queue_atom) do
    Application.get_env(:exq, :throttler, [])
    |> Keyword.get(queue_atom, nil)
  end

  def epoch_seconds(offset \\ 0) do
    Timex.DateTime.now
    |> Timex.shift(seconds: offset)
    |> Timex.format!("%s", :strftime)
  end

  def should_throttle?(redis, namespace, queue, throttle_opts) do
    period = throttle_opts |> Keyword.get(:period, 0)
    throttle_redis_key = namespace <> ":stat:#{queue}:processed_with_timestamp"

    @redis.Connection.zcount!(redis, throttle_redis_key, "(" <> epoch_seconds(-period), epoch_seconds) >= (throttle_opts |> Keyword.get(:threshold, :infinity))
  end

  def get_job_details(pipeline) do
    namespace = pipeline |> Map.get(:namespace, "exq")
    job_json_map = pipeline
                   |> Map.get(:assigns, %{})
                   |> Map.get(:job_json, "{}")
                   |> Poison.decode!
    queue = job_json_map |> Map.get("queue", "default")
    class = job_json_map |> Map.get("class", "") |> String.to_atom
    args = job_json_map |> Map.get("args", [])
    %{namespace: namespace, queue: queue, class: class, args: args}
  end

  def execute(job_details, pipeline) do
    %{queue: queue} = job_details
    queue_atom = queue |> String.to_atom
    @config.get(:throttler)
    |> Keyword.get(queue_atom, nil)
    |> do_execute(job_details, pipeline)
  end

  def do_execute(nil, _, pipeline), do: pipeline
  def do_execute(throttle_opts, job_details, pipeline) do
    %{namespace: namespace, queue: queue} = job_details
    get_redis_pid
    |> should_throttle?(namespace, queue, throttle_opts)
    |> throttle(throttle_opts, job_details, pipeline)
  end

  def throttle(true, throttle_opts, job_details, pipeline) do
    %{queue: queue, class: class, args: args} = job_details
    %{assigns: assigns} = pipeline
    delay = throttle_opts |> Keyword.get(:delay, 0)
    @exq_middleware.Job.remove_job_from_backup(pipeline)
    @exq.enqueue_in(Exq, queue, delay, class, args)
    @manager.job_terminated(assigns.manager, assigns.namespace, assigns.queue, assigns.job_json)
    @pipeline.terminate(pipeline)
  end
  def throttle(_, _, _, pipeline), do: pipeline


  def record_throttled(nil, _, _, _) do
    {:ok, 0}
  end
  def record_throttled(throttler_opts, redis, namespace, queue) do
    integer_epoch = epoch_seconds |> String.to_integer
    period = throttler_opts |> Keyword.fetch!(:period)
    obsolete_since = integer_epoch - period
    command_list = []
                    |> List.insert_at(-1, ["ZREMRANGEBYSCORE", @redis.JobQueue.full_key(namespace, "stat:#{queue}:processed_with_timestamp"), "-inf", "(#{obsolete_since}"])
                    |> List.insert_at(-1, ["ZADD", @redis.JobQueue.full_key(namespace, "stat:#{queue}:processed_with_timestamp"), integer_epoch, Time.now(:milliseconds)])
    {:ok, [_, _]} = @redis.Connection.qp(redis, command_list)
    {:ok, 0}
  end
end
