# Tweeter-Engine-Elixir-Phoenix

## Team
Amrutha Alaparthy (6690-5246) & Meghana Madineni (9197-8425)

## Run Instructions
1. ### Start the _Phoenix Server_
    * Go to the directory of the project.
    * Install dependencies with the command below.<br/>
    `mix deps.get` 
    * Install Node.js dependencies with the command below. <br/>
    `cd assets && npm install`
    * Start Phoenix endpoint with the following instruction. <br/>
    `mix phx.server`
    
2. ### To Observe _Tweeter Activity_
    * To __open the application__
      * Visit [`localhost:4000`](http://localhost:4000) from your browser.
    * In __Login and Register__ page <br/> 
      * Enter the _username_ and _password_ of the user. <br/> 
      * The user has to _sign up_ first, in order to _login_.
    * To __Follow users__ <br/>
       * Once the user registers and is logged in, the user can follow other users by giving the _username_ and clicking on the _Follow_ button.
    * To __Tweet__
       * To send the tweet, the user can enter the _text_ and click the _Tweet_ button.
       * Tweets can include _hashtags_ or _mentions_. 
       * This _tweet_ is sent to the _followers_ of the user and it gets displayed on their respective _timelines_.
    * __Retweet Activity__
       * Once any user receives tweet, the user can _re-tweet_ by clicking on the _Retweet_ button, this functionality is same as that of tweet.
    * __Querying the tweets__
       * The user can _query_ for _hashtags or mentions_ by entering it and clicking the _Query_ button. This will list all the tweets which contains the particular hashtag or mention.
    * To __Logout__
       * To logout, the user can click the _Signout_ button.
