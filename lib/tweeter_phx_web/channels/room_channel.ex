defmodule TweeterPhxWeb.RoomChannel do
    use Phoenix.Channel
    require Logger

    def join("dos", message, socket) do
        Process.flag(:trap_exit, true)
        :timer.send_interval(10000, :ping)
        send(self, {:after_join, message})
        {:ok, socket}
    end

    def handle_info({:after_join, msg}, socket) do
        broadcast! socket, "user:entered", %{user: msg["user"]}
        push socket, "join", %{status: "connected"}
        {:noreply, socket}
    end

    # def handle_in("login", user, socket) do
    #     IO.puts("Login check #{user["username"]}");
    #     push socket, "login_status", %{status: "success", username: user["username"]}
    #     {:noreply, socket}
    # end

    def handle_info(:ping, socket) do
        push socket, "new:msg", %{user: "Server", body: "ping"}
        {:noreply, socket}
    end

    def terminate(reason, _socket) do
        :ok
    end

    def handle_in("register_user", userInfo, socket) do
        username = userInfo["username"]
        password = userInfo["password"]
        res = GenServer.call(String.to_atom("mainserver"), {:register_user, username, password})
        IO.puts("Registering Response: #{inspect res}")
        if res do
            socket = assign(socket, :username, username)
            IO.inspect socket
            IO.puts("value: #{socket.assigns.username}")
            :ets.insert_new(:sockets, {username, socket})
            push socket, "registration_status", %{status: "success", username: userInfo["username"]}
        else
            push socket, "registration_status", %{status: "failure", username: userInfo["username"]}
        end
        {:noreply, socket}
    end

    def handle_in("login", userInfo, socket) do
        username = userInfo["username"]
        password = userInfo["password"]
        res = GenServer.call(String.to_atom("mainserver"), {:login, username, password})
        IO.puts("Login Response: #{inspect res}")
        if res do
            :ets.insert(:sockets, {username, socket})
            socket = assign(socket, :username, username)
            IO.inspect socket
            push socket, "login_status", %{status: "success", username: userInfo["username"]}
        else
            push socket, "login_status", %{status: "failure", username: userInfo["username"]}
        end
        {:noreply, socket}
    end

    def handle_in("logout", userInfo, socket) do
        IO.puts("Logging out")    
        username = userInfo["username"]
        res = GenServer.call(String.to_atom("mainserver"), {:logout, username})
        if res do
            push socket, "logout_status", %{status: "success", username: userInfo["username"]}
        else
            push socket, "logout_status", %{status: "failure", username: userInfo["username"]}
        end
        {:noreply, socket}    
    end

    def handle_in("follow", info, socket) do
        to = info["to"]
        from = info["from"]
        IO.puts("Phoenix Follow")
        res = GenServer.call(String.to_atom("mainserver"), {:follow, to, from})
        if res do
            socket = assign(socket, :username, from)
            IO.inspect socket
            IO.puts("value: #{socket.assigns.username}")
            push socket, "follow_status", %{status: "success", username: info["from"]}
        else
            push socket, "follow_status", %{status: "failure", username: info["from"]}
        end
        {:noreply, socket}
    end

    def handle_in("query", info, socket) do
        username = info["username"]
        querytext = info["querytext"]
        IO.puts("Querying for #{querytext} in DB")
        socket = assign(socket, :username, username)
        tweet_list = GenServer.call(String.to_atom("mainserver"), {:query, querytext})
        # Add tweet to ETS table
        IO.inspect tweet_list
        case tweet_list do
          [] ->  push socket, "query_status", %{status: "empty", tweet_list: tweet_list}
          _ ->   push socket, "query_status", %{status: "success", tweet_list: tweet_list}
        end
        {:noreply, socket}    
    end

    def handle_in("tweet", info, socket) do
        username = info["username"]
        message = info["message"]
        socket = assign(socket, :username, username)
        {_,followers} = GenServer.call(String.to_atom("mainserver"), {:get_followers, username})
        # Add tweet to ETS table
        GenServer.call(String.to_atom("mainserver"), {:tweet, username, message})
        broadcast! socket, "on_tweet", %{username: username, message: message,followers: followers}
        {:noreply, socket}    
    end

    intercept ["on_tweet"]
    def handle_out("on_tweet", tweet, socket) do
        # IO.inspect tweet
        username = tweet.username
        IO.puts("tweeter:#{username}")
        # [[this_socket_user]] = :ets.match(:sockets, {:"$1", socket})
        # {status, tweet_followers} = GenServer.call(String.to_atom("mainserver"), {:get_followers, username});
        # IO.inspect(tweet_followers)
        
        try do
                IO.puts("My name: #{socket.assigns.username}")

          this_socket_user = socket.assigns.username
          # IO.inspect(this_socket_user)
          case tweet.followers do
             [] -> 
                  {:noreply, socket}
              _ -> 
                  IO.inspect tweet.followers
                  if Enum.member?(tweet.followers, this_socket_user) do
                      push socket, "on_tweet",  %{status: "success", tweet: tweet} 
                      {:noreply, socket}   
                  else
                      {:noreply, socket}
                  end
             
          end
        rescue 
          KeyError ->
          IO.inspect(socket)
        end
          # push socket, "on_tweet",  %{status: "success", tweet: tweet, followers: tweet_followers} 
          {:noreply, socket}
        # end
    end


end