defmodule TweeterPhxWeb.Worker do
    use GenServer
    require Logger

    def start_link() do
        #Agent.start_link(fn -> initial_state end, name: __MODULE__)
        IO.puts("Started: M<ain")
        GenServer.start_link( __MODULE__, {}, name: String.to_atom("mainserver"))
    end
    
    def init(state) do
        :ets.new(:users, [:set, :public, :named_table])
        :ets.new(:tweets, [:set, :public, :named_table])
        :ets.new(:online_users, [:set, :public, :named_table])
        :ets.new(:timeline, [:set, :public, :named_table])
        :ets.new(:hashtags, [:set, :public, :named_table])
        :ets.new(:mentions, [:set, :public, :named_table])
        {:ok, state}
    end

    def handle_call({:register_user, username, password}, from, state) do
        status = :ets.insert_new(:users, {username, password, [], [false, :os.system_time(:seconds)], from})
        if status do
            {:reply, true, state}    
        else
            {:reply, false, state}
        end       
    end

    def handle_call({:logout, username}, from, state) do
        try do
            [user] = :ets.match_object(:users, {username, :"_", :"_", :"_", :"_"})
            {username, password, followers, [state, t_register], pid} = user            
            :ets.insert(:users, {username, password, followers , [false, t_register], pid})
            online_tuple = :ets.lookup(:online_users, "online")
            [{"online", online}] = online_tuple
            online = online -- [from]
            :ets.insert(:online_users, {"online", online})
            
            # Logger.info("Logout Success!")
            # {:noreply, %{online: state.online -- [username], offline: state.offline ++ [username]}
            {:reply, true, state} 
        rescue
            e in MatchError ->
                {:reply, false, state}     
                
        end           
    end

    def handle_call({:login, username, password}, _from, state) do
        IO.puts("username_in:#{username}")
        try do
            IO.puts("username_in:#{username}")
            [user] = :ets.match_object(:users, {username, password, :"_", :"_", :"_"})
            {username, password, followers, [state, t_register], pid} = user
            :ets.insert(:users, {username, password, followers , [true, t_register], pid})
            online_tuple = :ets.lookup(:online_users, "online")
            online = []
            if online_tuple == [] do
                online = []
            else
                [{"online", online}] = online_tuple
            end
            online = online ++ [username]
            :ets.insert(:online_users, {"online", unique(online)})
            {:reply, true, state}
        rescue
            MatchError ->
                    {:reply, false, state}    
        end
    end


    def handle_call({:follow, to, from}, _from, state) do
        IO.puts("following")
        try do
            [to_user] = :ets.match_object(:users, {to, :"_", :"_", :"_", :"_"})
            [from_user] = :ets.match_object(:users, {from, :"_", :"_", :"_", :"_"})
            {from_username, from_password, from_followers, [from_state, from_t_register], from_pid} = from_user
            {username, password, followers, [state, t_register], pid} = to_user
            :ets.insert(:users, {username, password, followers ++ [from_username] , [state, t_register], pid})
            IO.puts("followed")
            IO.inspect followers ++ [from_username]
            {:reply, true, state} 
        rescue
            MatchError -> 
                IO.puts("Failed to follow")
                {:reply, false, state} 
        end   
    end

    def handle_call({:get_followers, username}, from, state) do
        IO.puts("Getting followers of #{username}")
        try do
            [user] = :ets.match_object(:users, {username, :"_", :"_", :"_", :"_"})
            {username, password, followers, [state, t_register], pid} = user
            IO.inspect followers
            {:reply, {true, followers}, state} 
        rescue
            MatchError -> 
            IO.puts("Get followers Match error")
                {:reply, {false, []}, state} 
        end         
    end

    def handle_call({:tweet, username, tweet}, _from, state) do
        {hashtags, mentions} = parse_tweets(tweet)
        IO.puts("hashtags #{inspect hashtags}")
        IO.puts("mentions #{inspect mentions}")
        tweet_id = get_random_id()
        
        :ets.insert(:tweets, {tweet_id, username, username, tweet, {hashtags, mentions}, 0})
        Enum.each(hashtags, fn(ht) -> 
            hashtag = :ets.lookup(:hashtags, ht)
            if hashtag == [] do
                :ets.insert(:hashtags, {ht, [tweet]})
                IO.inspect :ets.lookup(:hashtags, ht)             
            else
                [{ht, tweets}] = hashtag
                tweets = tweets ++ [tweet]
                :ets.insert(:hashtags, {ht, tweets})
                IO.inspect :ets.lookup(:hashtags, ht)
            end
        end)
        
        Enum.each(mentions, fn(mn) -> 
            mention = :ets.lookup(:mentions, mn)
            if mention == [] do
                :ets.insert(:mentions, {mn, [tweet]})    
            else
                [{mn, tweets}] = mention
                tweets = tweets ++ [tweet]
                :ets.insert(:mentions, {mn, tweets})
            end
        end)
        {:reply, {}, state}
    end

    def handle_call({:query, query_text}, _from, state) do
        response = []
        query_string = String.slice(query_text, 1..-1)
        IO.puts("Querying: #{query_string}")
        if String.starts_with?(query_text, "#") do
            hashtag = :ets.lookup(:hashtags, query_string)
            IO.inspect hashtag
            case hashtag do
              [] -> response = []
              _ ->
                [{_, tweets}] = hashtag

                response = tweets  
                IO.inspect response  
            end    
        end

        if String.starts_with?(query_text, "@") do
            mention = :ets.lookup(:mentions, query_string)
            unless mention == [] do
                [{query_string, tweets}] = mention
                response = tweets
                IO.inspect response    
            end    
        end
        IO.inspect response
        {:reply, response, state}
    end

    # def handle_cast({:register_user, username, password, from}, state) do
    #     # User Table {username, password, [followers], [login_status, last_logout_time], from}
    #     # Logger.info "Registering User #{inspect username}"
    #     status = :ets.insert_new(:users, {username, password, [], [false, :os.system_time(:seconds)], from})
    #     if status do
    #         # Logger.info "Registration Success"
    #         GenServer.cast(from, {:registration_status, true, "Registration successful!"})
    #     else
    #         # Logger.info "Registration Failure"
    #         GenServer.cast(from, {:registration_status, false, "User exists!"})
    #     end
    #     {:noreply, state}
    # end



    # def handle_cast({:login, username, password, from}, state) do
    #     # Logger.info("Login #{username}")
    #     try do
    #         [user] = :ets.match_object(:users, {username, password, :"_", :"_", :"_"})          
    #         {username, password, followers, [state, t_register], pid} = user
    #         :ets.insert(:users, {username, password, followers , [true, t_register], pid})
    #         online_tuple = :ets.lookup(:online_users, "online")
    #         online = []
    #         if online_tuple == [] do
    #             online = []
    #         else
    #             [{"online", online}] = online_tuple
    #         end
    #         online = online ++ [from]
    #         :ets.insert(:online_users, {"online", unique(online)})

    #         offline_timeline = :ets.lookup(:timeline, from)
    #         # IO.inspect offline_timeline

    #         if(offline_timeline == []) do
    #             # Do nothing; Nothing to send
    #         else
    #             [{from, tweets}] = offline_timeline
    #             Enum.each(tweets, fn(tweet_id) ->
    #                 [[tweet]]  = :ets.match(:tweets, {tweet_id, :"_", :"_", :"$1", :"_" , :"_"})
    #                 GenServer.cast(from, {:tweet, tweet_id, tweet})
    #             end)
    #             :ets.delete(:timeline, from)
    #         end
    #         GenServer.cast(from, {:login_status, true, "Login Success"})
    #         # Logger.info "Login success, Changing status to online"
    #         # {:noreply, %{online: state.online ++ [username], offline: state.offline -- [username]}}            
            
    #     rescue
    #         MatchError ->
    #             GenServer.cast(from, {:login_status, false, "Login Failed"})
    #             Logger.info "Login failed"
    #     end
    #     {:noreply, state}
    # end

    def handle_cast({:logout, username, from}, state) do
        try do
            [user] = :ets.match_object(:users, {username, :"_", :"_", :"_", :"_"})
            # IO.inspect user
            # options = elem(user, 3)
            # options = List.insert_at(options, 0, false)
            # options = List.insert_at(options, 1, :os.system_time(:seconds))
            # user = Tuple.insert_at(user, 3, options)
            {username, password, followers, [state, t_register], pid} = user            
            :ets.insert(:users, {username, password, followers , [false, t_register], pid})
            online_tuple = :ets.lookup(:online_users, "online")
            [{"online", online}] = online_tuple
            online = online -- [from]
            :ets.insert(:online_users, {"online", online})
            GenServer.cast(from, {:logout_status, true, "Logout Success!"})
            # Logger.info("Logout Success!")
            # {:noreply, %{online: state.online -- [username], offline: state.offline ++ [username]}
        rescue
            e in MatchError ->
                GenServer.cast(from, {:logout_status, false, "Logout Failed!"})
                Logger.info("Logout failed!")
        end
        {:noreply, state}                    
    end


    def handle_cast({:follow, to, from}, state) do
        try do
            [to_user] = :ets.match_object(:users, {to, :"_", :"_", :"_", :"_"})
            [from_user] = :ets.match_object(:users, {from, :"_", :"_", :"_", :"_"})
            {from_username, from_password, from_followers, [from_state, from_t_register], from_pid} = from_user
            {username, password, followers, [state, t_register], pid} = to_user
            :ets.insert(:users, {username, password, unique(followers ++ [from_pid]) , [state, t_register], pid})
            # Logger.info("Follow successful")
        rescue
            MatchError -> 
                Logger.info("Follow failed! #{to} ->#{from}" )
        end
        {:noreply, state}
    end

    def handle_cast({:query, from_pid, query}, state) do
        response = []
        query_string = String.slice(query, 1..-1)
        if String.starts_with?(query, "#") do
            hashtag = :ets.lookup(:hashtags, query_string)
            unless hashtag == [] do
                [{query_string, tweet_ids}] = hashtag
                reponse = tweet_ids    
            end    
        end

        if String.starts_with?(query, "@") do
            mention = :ets.lookup(:mentions, query_string)
            unless mention == [] do
                [{query_string, tweet_ids}] = mention
                response = tweet_ids    
            end    
        end

        GenServer.cast(from_pid, {:query_response, response})
        {:noreply, state}
    end

    # # Tweet Structure: {random_id, from, owner, tweet, {hashtags, mentions}, count }
    def handle_cast({:tweet, from, tweet}, state) do
        {hashtags, mentions} = parse_tweets(tweet)
        tweet_id = get_random_id()
        
        :ets.insert(:tweets, {tweet_id, from, from, tweet, {hashtags, mentions}, 0})
        Enum.each(hashtags, fn(ht) -> 
            hashtag = :ets.lookup(:hashtags, ht)
            if hashtag == [] do
                :ets.insert(:hashtags, {ht, [tweet_id]})                
            else
                [{ht, tweet_ids}] = hashtag
                tweet_ids = tweet_ids ++ [tweet_id]
                :ets.insert(:hashtags, {ht, tweet_ids})
            end
        end)
        
        Enum.each(mentions, fn(mn) -> 
            mention = :ets.lookup(:mentions, mn)
            if mention == [] do
                :ets.insert(:mentions, {mn, [tweet_id]})    
            else
                [{mn, tweet_ids}] = mention
                tweet_ids = tweet_ids ++ [tweet_id]
                :ets.insert(:mentions, {mn, tweet_ids})
            end
        end)
        
        # Logger.info(tweet_id)
        # Logger.info("Tweet successfully generated!")
        try do
            [[pid]] = :ets.match(:users, {from, :"_", :"_", :"_", :"$1"})
            GenServer.cast(pid, {:tweet_status, true})
            [[followers]] = :ets.match(:users, {from, :"_", :"$1", :"_", :"_"})
            # IO.puts "Followers : #{inspect followers}"
            [[online]] = :ets.match(:online_users, {"online", :"$1"})
            # IO.puts "Online users : #{inspect online}"
            online_followers = find_intersection(followers, online)
            # IO.puts "Online Followers : #{inspect online_followers}"
            Enum.each(online_followers, fn(user) ->
                GenServer.cast(user, {:tweet, tweet_id, tweet})
                # Logger.info("Tweet sent")
                end
            )
            offline_followers = followers -- online_followers
            # Logger.info "Offline followers"
            # IO.inspect offline_followers
            Enum.each(offline_followers, &save_offline_timeline(&1, tweet_id))
        rescue
            MatchError ->
                Logger.info "Tweeting failed"
        end
        {:noreply, state}
    end

    def handle_cast({:retweet, from, owner_tweetid}, state) do
        # {hashtags, mentions} = parse_tweets(tweet)
        tweet_id = get_random_id()
        [[pid]] = :ets.match(:users, {from, :"_", :"_", :"_", :"$1"})
        GenServer.cast(pid, {:tweet_status, true})        
        [[owner , tweet, {hashtags, mentions}]] = :ets.match(:tweets, {owner_tweetid, :"_", :"$1", :"$2",  :"$3", :"_"})
        :ets.insert(:tweets, {tweet_id, from, owner, tweet, {hashtags, mentions}, 0})
        [[followers]] = :ets.match(:users, {from, :"_", :"$1", :"_", :"_"})
        [[online]] = :ets.match(:online_users, {"online", :"$1"})        
        online_followers = find_intersection(followers, online)
        Enum.each(online_followers, fn(user) ->
            GenServer.cast(user, {:tweet, tweet_id, tweet})
            end
        )
        offline_followers = followers -- online_followers
        Enum.each(offline_followers, &save_offline_timeline(&1, tweet_id))
        {:noreply, state}     
    end

    def handle_cast({:ack_tweet, tweet_id}, state) do
        [tweet] = :ets.lookup(:tweets, tweet_id)
        {random_id, from, owner, tweet, {hashtags, mentions}, count} = tweet
        :ets.insert(:tweets, {random_id, from, owner, tweet, {hashtags, mentions}, count+1})
        # Logger.info "Tweets acknowledged : #{count+1}"
        {:noreply, state}        
    end

    ## Utils
    def unique(list) do
        MapSet.to_list(MapSet.new(list))
    end

    def save_offline_timeline(user, tweet) do
        try do
            # Logger.info "Saving offline tweet"
            [[timeline_tweets]] = :ets.match(:timeline, {user, :"$1"})
            # Logger.info timeline_tweets
            timeline_tweets = timeline_tweets ++ [tweet]
            # Logger.info timeline_tweets
            :ets.insert(:timeline, {user, timeline_tweets})
        rescue
            MatchError -> 
                :ets.insert(:timeline, {user, [tweet]})
                # Logger.info "Saving offline tweets - new"
        end    
    end

    defp find_intersection(list1, list2) do
        MapSet.to_list(MapSet.intersection(MapSet.new(list1), MapSet.new(list2)))
    end
    
    defp parse_tweets(tweet) do
        tweet = String.trim(tweet)
        words = String.split(tweet, " ")
        mentions = Enum.map(Enum.filter(words, fn(x) -> String.starts_with?(x, "@") end), &String.slice(&1, 1..-1))
        hashtags = Enum.map(Enum.filter(words, fn(x) -> String.starts_with?(x, "#") end),  &String.slice(&1, 1..-1))
        {hashtags, mentions}
    end

    defp is_user_online(user) do
        [user] = :ets.lookup(:users, user)
        options = elem(user, 3)
        Enum.at(options, 0)
    end

    defp get_random_id() do
        :crypto.strong_rand_bytes(16) |> Base.url_encode64 
    end
end