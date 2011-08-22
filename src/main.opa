// 
//  main.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-06.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess


/* Message received about the state of the game. */
@client message_recieved(msg: message) = 
    match msg with 
        | { joining = user } -> Dom.hide(#waiting)
        | { state   = board } ->
            do Dom.transform([#color_of_current_player <- colorc_to_string(board.current_color)])
            do if Option.get(Game.get_state()).color == board.current_color then
                Dom.hide(#waiting)
            else
                do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for " ^ colorc_to_string(board.current_color))
                Dom.show(#waiting)
             Board.update(board)
            

@client when_ready(name,color): void = (
    channel  = Option.get(Game.get_state()).channel
    do Dom.set_text(#color_of_player,colorc_to_string(color))
    do Dom.set_text(#name_of_game, name)
    do Dom.set_text(#color_of_current_player, colorc_to_string({white}))
    do Network.observe(message_recieved, channel)
    do Option.iter( state -> (
        if state.color == {white} then 
            Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for black player")
        else 
            Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for white player")
    ),Game.get_state())
    
    Board.prepare(Board.create())
)

boardgame(name: string) = (
    // this page will only get rendered if the user is logged in so it's safe to 'get'.
    match User.get_status() with 
        | {user = user} -> (
            match Game.get(name) with 
                | { some = game } -> (
                    
                    xml = color -> 
                        <div onready={_ -> Network.add_callback(game_finished_recieved, game_observer)}>
                        <div onready={_ -> when_ready(name,color) } class="game">
                            {Chat.create_with_channel(user.name, NetworkWrapperChat.memo(game.name ^ "_chat"))}
                            {Template.parse(Template.default, @static_content("resources/board.xmlt")()) |> Template.to_xhtml(Template.default, _)}
                        </div>
                        </div>

                    if (Option.get(game.white) == user) then 
                        Resource.styled_page("Chess", Page.style, xml({white}))
                    else 
                        Resource.styled_page("Chess", Page.style, xml({black}))
                ) 
                | {none}  -> Page.fourOfour()
        )
        | {unlogged} -> Page.fourOfour() //Shouldn't be able to happen here as we checked in the routing.
)

/*
    {Routing logic}
*/

login_required( page: -> resource ) = 
    if User.is_logged_in() then page() else User.login_view()

start(uri) = 
    match uri with
        | { path = [] ... }            -> login_required( -> Page.main() )
        | { path = ["login"] ... }     -> User.login_view()
        | { path = ["signup"] ...}     -> User.signup_view()
        | { path = ["game",x|xs] ...}  -> login_required( -> boardgame(x) )
        | { path = ["user", x|xs] ...} -> User.withUserNamed(x, User.page_view(_), Page.fourOfour)
        | { path = x ...}              -> Page.fourOfour()


/**
 * Statically embed a bundle of resources
 */
server = Server.of_bundle([@static_include_directory("resources")])

/**
 * Launch the [start] dispatcher
 */
server = Server.simple_dispatch(start)