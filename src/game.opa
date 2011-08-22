// 
//  game.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-13.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

/*
    Network for recording stats when a game is finished. I'm using this so it'll be 
    possible to update the win/losses count of a player inside a method tagged as client. 
*/

type game_finished = { winner: colorC }

@publish game_observer = Network.cloud("game_observer") : Network.network(game_finished) 

game_finished_recieved(game_finished) = User.withUser( user -> 
    if game_finished.winner == Option.get(Game.get_state()).color then 
        do User.update({ user with wins = user.wins+1})
        do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "You've won!")
        Dom.show(#waiting)
    else 
        do User.update({ user with losses = user.losses+1})
        do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "You've lost!")
        Dom.show(#waiting)
, void)

/*
    Game module and related db 
*/

db /game: stringmap(option(game))
db /game[_] = none 

type game = { 
    white: option(user) ; 
    black: option(user) ; 
    name: string 
}

type Game.status = { 
    game: string ; 
    color: colorC ; 
    channel: Network.network(message) 
}

Game = {{
    
    user_state = UserContext.make({none}: option(Game.status))

    get_state() = UserContext.execute((a -> a), user_state)

    get(name: string): option(game) = /game[name]

    join(name: string, user: user): outcome(game,list(string)) =
        match /game[name] with 
            | { some = game } -> 
                g = { game with black = some(user) }
                channel = NetworkWrapper.memo(name): Network.network(message) // should return the network already created in 'create'
                do Network.broadcast({ joining = user},channel) 
                do /game[name] <- some(g)
                do UserContext.change(( _ -> { some = { game = name color = {black} channel = channel }}), user_state)
                do User.update({ user with games = user.games + 1})
                { success = g}
            | { none } -> { failure = ["No such game exists."] }
    
    create(name: string, user: user): outcome(game,list(string)) = 
        match /game[name] with 
            | { some = game } -> { failure = ["A game with that name is already in progress."]}
            | { none } -> ( 
                if String.is_empty(name) then (
                    { failure = ["The name has to be non-empty"]}
                ) else (
                    game = { name = name white = some(user) black = none }
                    channel = NetworkWrapper.memo(name): Network.network(message)
                    do /game[name] <- some(game)
                    do UserContext.change(( _ -> { some = { game = name color = {white} channel = channel }}), user_state)
                    do User.update({ user with games = user.games + 1})
                    { success = game }
                )
            )
}}