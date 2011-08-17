// 
//  game.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-13.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess.game 

import chess.user

db /game: stringmap(option(game))
db /game[_] = none 

type game = {
    white: option(user) ; 
    black: option(user) ; 
    name: string 
}

Game = {{

    get(name: string): option(game) = /game[name]

    // join(game: game, user:user ) = 
    
    create(name: string, user: user): outcome(game,list(string)) = 
        match /game[name] with 
            | { some = game } -> { failure = ["A game with that name is already in progress."]}
            | { none } -> ( 
                if String.is_empty(name) then (
                    { failure = ["The name has to be non-empty"]}
                ) else (
                    game = { name = name white = some(user) black = none }
                    do /game[name] <- some(game)
                    { success = game }
                )
            )
}}