defmodule TweeterPhxWeb.Router do
  use TweeterPhxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TweeterPhxWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login/:username", PageController, :login
   # get "/register", PageController, :register
   # get "/timeline", PageController, :timeline
  end

  # Other scopes may use custom stacks.
  # scope "/api", TweeterPhxWeb do
  #   pipe_through :api
  # end
end
