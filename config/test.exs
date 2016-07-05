use Mix.Config

config :exq_throttler,
  mock: %{
    exq: Exq.Test.Mocks.Exq,
    pipeline: Exq.Test.Mocks.Pipeline,
    middleware: Exq.Test.Mocks.Middleware,
    redis: Exq.Test.Mocks.Redis,
    support: Exq.Test.Mocks.Support
  }
