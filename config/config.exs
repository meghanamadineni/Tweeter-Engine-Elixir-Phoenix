# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :tweeter_phx,
  ecto_repos: [TweeterPhx.Repo]

# Configures the endpoint
config :tweeter_phx, TweeterPhxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VleSmViQ/Sdci7h6HV0bbi7AarM81SrsdP0Co+XQ9nJPWxogGX4EuxH/CBXbjE4m",
  render_errors: [view: TweeterPhxWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TweeterPhx.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
