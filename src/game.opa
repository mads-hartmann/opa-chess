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
    game_state = Option.get(Game.get_state())
    do if game_finished.winner == game_state.color then 
        do User.update({ user with wins = user.wins+1})
        do Dom.select_raw("#waiting h1") |> Dom.set_html_unsafe(_, "Congratulations, You've won! Head back to the <a href='/'>menu</a>")
        Dom.show(#waiting)
    else 
        do User.update({ user with losses = user.losses+1})
        do Dom.select_raw("#waiting h1") |> Dom.set_html_unsafe(_, "Buggers, you've lost! Head back to the <a href='/'>menu</a>")
        Dom.show(#waiting)
    /game[game_state.game] <- {none}
, void)

/* 
   This is very hacky :,-(  
   
   Tried to add a board to the Game.status type but safari couldn't handle it for 
   some reason. This seems to work. 
*/
@publish persistent_game_state = Network.cloud("persistent_game_state") : Network.network(board) 
persistent_game_state_changed(gameName: string, board: board) = 
(
    Option.iter( game -> 
        
        /game[gameName] <- some({ game with board = some(board) })
    
     ,/game[gameName])
)

/*
    Game module and related db 
*/

db /game: stringmap(option(game))
db /game[_] = none 

// Some defaults. Should never be used as the default game is none
db /game[_]/some/board/some/current_color = { black }
db /game[_]/some/board/some/chess_positions[_][_]/piece/some/kind = { bishop }
db /game[_]/some/board/some/chess_positions[_][_]/piece/some/color = { black }

type game = { 
    white: option(user) 
    black: option(user) 
    name: string 
    board: option(board)
}

type Game.status = { 
    game: string  
    color: colorC 
    channel: Network.network(message) 
}

Game = {{
    
    /*
        Data related
    */
        
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
            | { none } -> ( 
                if String.is_empty(name) then (
                    { failure = ["The name has to be non-empty"]}
                ) else (
                    game = { name = name white = some(user) black = none board = some(Board.create()) }
                    channel = NetworkWrapper.memo(name): Network.network(message)
                    do /game[name] <- some(game)
                    do UserContext.change(( _ -> { some = { game = name color = {white} channel = channel }}), user_state)
                    do User.update({ user with games = user.games + 1})
                    { success = game }
                )
            )
            | _ -> { failure = ["A game with that name is already in progress."]}
    
    /*
        View related 
    */
    
    // Message received about the state of the game. 
    @client message_recieved(msg: message) = 
        match msg with 
            | { state   = board } ->
                do Dom.transform([#color_of_current_player <- colorc_to_string(board.current_color)])
                do if Option.get(Game.get_state()).color == board.current_color then
                    Dom.hide(#waiting)
                else
                    do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for " ^ colorc_to_string(board.current_color))
                    Dom.show(#waiting)
                Board.update(board)
            | { joining = _ } -> Dom.hide(#waiting)

    // invoked when the game_view is ready to initialize the dom with the appropriate data. 
    @client when_ready(name,color,board,game_state,game): void = (
        channel = game_state.channel
        
        do Dom.set_text(#color_of_player,colorc_to_string(color))
        do Dom.set_text(#name_of_game, name)
        do Dom.set_text(#color_of_current_player, colorc_to_string({white}))
        do Network.observe(message_recieved, channel)
        
        do if Option.is_none(game.black) then
            Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for other player to join.")
        else 
            if game_state.color == color then 
                Dom.hide(#waiting)
            else 
                do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for other player to move.")
                Dom.show(#waiting)

        Board.prepare(board)
    )

    game_view(name: string) = User.withUser( user -> 
        match Game.get(name) with 
            | { some = game } -> (

                if Option.get(game.white) == user || Option.get(game.black) == user then
                    board = Option.bind( g -> g.board ,/game[name]) |>
                            Option.default(Board.create(),_)
                    game_state  = Option.get(Game.get_state())

                    xml = color -> 
                        <div onready={_ -> Network.add_callback(game_finished_recieved, game_observer)}>
                        <div onready={_ -> Network.add_callback(persistent_game_state_changed(name,_), persistent_game_state)}>
                        <div onready={_ -> when_ready(name,color, board, game_state, game) } class="game">
                                {Chat.create_with_channel(user.name, NetworkWrapperChat.memo(game.name ^ "_chat"))}
                                {Template.parse(Template.default, @static_content("resources/board.xmlt")()) |> Template.to_xhtml(Template.default, _)}
                        </div>
                        </div>
                        </div>

                    if (Option.get(game.white) == user) then 
                        Resource.styled_page("Chess", Page.style, xml({white}))
                    else 
                        Resource.styled_page("Chess", Page.style, xml({black}))
                else Page.fourOfour()
            ) 
            | {none}  -> Page.fourOfour()
    ,User.login_view()) // 404 shouldn't happen

    
}}