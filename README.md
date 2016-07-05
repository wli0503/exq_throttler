# ExqThrottler

A throttler implementation for Exq.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exq_throttler to your list of dependencies in `mix.exs`:

        def deps do
          [{:exq_throttler, "~> 0.0.1"}]
        end

## Usage

  1. Add `Exq.Middleware.Throttler` to your `config/*.exs`:
  ```
  # in config/dev.exs
  config :exq,
  # Note here that Exq.Middleware.Job must exist before Exq.Middleware.Throttler since
  # Throttler requires information from Job
  middleware: [Exq.Middleware.Job, Exq.Middleware.Throttler, <other middlewares>]
  ```

  2. Add configurations for `Exq.Middlware.Throttler` in `config/*.exs`:
  ```
  # in config/dev.exs
  throttler: [
    <queue_name>: [
      period: 60,      #  
      threshold: 3,    #
      delay: 60
    ]
  ]
  ```
  period and threshold in combine determines when it should throttle. Throttler will check the number of jobs in the period, then delay others according to the delay set in the configuration. Note that it's recommended to have delay >= period.
