// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: m1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.
//////////////////////////////////
socket.connect()

let channel = socket.channel("dos", {})

// Now that you are connected, you can join channels with a topic:
channel.join()
  .receive("ok", resp => { console.log("Connected to Server", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

$(document).ready(function(){
  // channel.push("set_socket")
  // $("#status").hide();
  setTimeout(() =>  {
    $(".jumbotron").hide()
  }, 4000);
});

if(document.getElementById("login")){
  $("#login").click(function(){
    channel.push('login',  {username: $("#username").val(), password: $("#password").val()});
  });
  $("#register").click(function(){
    channel.push('register_user', {username: $("#username").val(), password: $("#password").val()});
  });
}
if(document.getElementById("tweet")){
  $("#tweet").click(function(){
    console.log( "Tweeting:" + $("#tweet_text").val())
    channel.push('tweet', {username: $("#username").html(), message: $("#tweet_text").val()})
  })

  $("#follow").click(function(){
    console.log("Following")
    channel.push('follow', {from: $("#username").html(), to: $("#follow_user").val()})
  })

  $("#logout").click(function(){
    console.log("Logging out")
    channel.push('logout', {username: $("#username").html()});
  })

  $(document.body).on('click','.retweet', function(e) { 
    console.log($(this).prev().html())
    console.log("retweeting" + $("#username").html())
    channel.push('tweet', {username: $("#username").html(), message: $(this).prev().html()})
   });
   
   $("#query").click(function(){
    console.log("Querying for Tweets");
    channel.push('query', {username: $("#username").html(), querytext: $("#query_text").val()})
   });

}


//////////////////////////////////


channel.on("new:msg", function(response){ //Regular Ping
  // $("#status").text("Connected")
  console.log("PING response:" + response["user"]);
});

channel.on('login_status', payload => {
    if(payload.status == "success"){
      console.log("Login Success")
      window.location.href = 'http://localhost:4000/login/' + payload.username
    }else{
      console.log("Login failed");
      $("#status").attr("display", "block")
      $("#status").show(500);
    }
});

channel.on('registration_status', payload => {
  if(payload.status == "success"){
    console.log("Registration Success")
    channel.push('login',  {username: payload.username, password: payload.username});
  }else{
    console.log("Registration failed");
  }
});

channel.on('logout_status', payload =>{
  if(payload.status == "success"){
    console.log("Logout Success");
    window.location.href = "http://localhost:4000"
  }else{
    console.log("Logout Failed")
  }
})

channel.on('follow_status', payload => {
  if(payload.status == "success"){
    console.log("Follow Success")
  }else{
    console.log("Follow failed");
  }
});

channel.on('on_tweet', payload => {
  if(payload.status == "success"){
    // console.log(payload.followers)
    // if(payload.followers.indexOf($("#username").html())!=-1){
      console.log("tweet received: " + payload.tweet.message);
      $("#tweet-list").append('<li class="media"><div class="media-body"> <span class="text-muted pull-right">' +
          '</span>  <strong class="text-success"> @' + payload.tweet.username + '</strong> <p>' + payload.tweet.message + ' </p>  <input type="button"  class="btn btn-info btn-sm retweet" value="Retweet"/></div>')
    // }
  }else{
    console.log("tweet fail")
  }
});

channel.on('query_status', payload => {
  if(payload.status == "empty"){
    console.log("No matching tweets")
  }else{
    let prefix = '<li class="media">' 
    let tweets = payload.tweet_list.join('</li><li class="media">')
  
    console.log("Tweets list found" + tweets);
    $("#query-results").html(prefix + tweets + "</li>");
  }
});


export default socket
