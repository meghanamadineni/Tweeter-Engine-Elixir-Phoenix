defmodule TweeterPhxWeb.PageController do
  use TweeterPhxWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def login(conn, params) do
    render conn, "hello.html", username: params["username"]
  end

  # def register(conn, params) do
  #   case  params["username"] == params["password"] do
  #     true -> render conn, "register.html", status: "Success"
  #     false -> render conn, "register.html", status: "Fail"
  #   end
  # end
end
