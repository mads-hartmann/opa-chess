// 
//  game.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-13.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess.game 

import chess.types
import chess.user

db /game: stringmap(option(game))
db /game[_] = none 

Game = {{
    
    user_state = UserContext.make({none}: option(Game.status))

    get_state() = UserContext.execute((a -> a), user_state)

    get(name: string): option(game) = /game[name]

    join(name: string, user: user): outcome(game,list(string)) =
        match /game[name] with 
            | { some = game } -> 
                g = { game with black = some(user) }
                channel = Network.cloud(name): Network.network(message)
                do /game[name] <- some(g)
                do UserContext.change(( _ -> { some = { game = name color = {black} channel = channel}}), user_state)
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
                    do /game[name] <- some(game)
                    channel = Network.cloud(name): Network.network(message)
                    do UserContext.change(( _ -> { some = { game = name color = {white} channel = channel }}), user_state)
                    { success = game }
                )
            )
}}