// 
//  main.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-06.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

/*
    {Pages}
*/

style = ["/resources/style.css"]

show_error(xs: list(string)) = 
    do Dom.remove_class(#error_container,"no_errors")
    do Dom.add_class(#error_container,"has_errors")
    do Dom.remove_content(#errors)
    List.iter( x -> Dom.transform([#errors +<- <li>{x}</li>]), xs)
    

fourOfour() = Resource.styled_page("Chess", style,
    <div id="fourofour"><h1>404</h1></div>
)

login() = Resource.styled_page("Chess", style,

    attempt_login() = 
        username = Dom.get_value(#username)
        password = Dom.get_value(#password)
        match User.login(username, password) with 
            | {true} -> Client.goto("/")
            | {false} -> 
                do show_error(["Wrong combination"])
                Dom.give_focus(#username)
                

    <div id="login" class="container">
        <div id="error_container" class="error_container no_errors">
            <ul id="errors"></ul>
        </div>
        <div class="content">
        <ul onready={ _ -> Dom.give_focus(#username) }>
            <li>
                <input id=#username placeholder="Username"/>
            </li>
            <li>
                <input id=#password placeholder="Password" type="password" onnewline={ _ -> attempt_login() }/>
            </li>
            <li>
                <input type="submit" value="Login" onclick={ _ -> attempt_login() } />
            </li>
        </ul>    
        </div>
        
    </div>
)
    
singup() = Resource.styled_page("Chess", style,
    <div id="signup" class="container">
        <div id="error_container" class="error_container no_errors">
            <ul id="errors"></ul>
        </div>
        <div class="content">
        <ul>
            <li>
                <label>Username</label>
                <input id=#username type="text" />
            </li>
            <li>
                <label>Email</label>
                <input id=#email type="text" />
            </li>
            <li>
                <label>Password</label>
                <input id=#password type="text" />
            </li>
            <li>
                <input type="submit" value="Sign up" onclick={ _ -> 
                    username = Dom.get_value(#username)
                    email    = Dom.get_value(#email)
                    password = Dom.get_value(#password)
                    match User.create(username, email, password) with 
                        | {success = user } -> Client.goto("/")
                        | {failure = failure } -> show_error(failure)                            
                } />
            </li>
        </ul>
        </div>
    </div>
)

/*
    Chat
*/

type chat_message = { author : string ; text : string }

@publish room = Network.cloud("room") : Network.network(chat_message)

user_update(x : chat_message) =
  line = <li>
            <span class="user">{x.author}:</span>
            {x.text}
        </li>
  do Dom.transform([#chat_messages +<- line ])
  Dom.scroll_to_bottom(#chat_messages)
  
broadcast(author) =
 do Network.broadcast({~author text=Dom.get_value(#entry)}, room)
 Dom.clear_value(#entry)

/*
    End of Chat
*/

lobby() = User.withUser( user -> (
    
    author = user.name
    
    join_back_onclick() = 
        do Dom.remove_class(#main, "hidden")
        Dom.add_class(#join,"hidden")
    
    create_back_onclick() = 
        do Dom.remove_class(#main, "hidden")
        Dom.add_class(#create,"hidden")
    
    create_game_onclick() = 
        name = Dom.get_value(#name)
        match Game.create(name, user) with 
            | {success = game } -> Client.goto("/game/" ^ name)
            | {failure = xs }   -> show_error(xs)
    
    menu_create_a_game_onclick() = 
        do Dom.remove_class(#create, "hidden")
        Dom.add_class(#main, "hidden")
    
    menu_join_a_game_onclick() = 
        do Dom.remove_class(#join,"hidden")
        do Dom.add_class(#main,"hidden")
        do Dom.remove_content(#gamesList)
        Map.To.val_list(/game) 
            |> List.filter_map( x -> x, _) 
            |> List.iter( x -> Dom.transform([#gamesList +<- 
                    <li onclick={_ -> 
                        match Game.join(x.name, user) with 
                            | { success = game } -> Client.goto("/game/" ^ x.name) 
                            | { failure = xs } -> show_error(xs)
                    }>{x.name}</li>]),
                _)

    Resource.styled_page("Chess", style,
        <div id="lobby" class="container">
        <div id="error_container" class="error_container no_errors">
            <ul id="errors"></ul>
        </div>
        <div class="content">
            <form>
                <ul id=#join class="hidden">
                    <a class="back" onclick={ _ -> join_back_onclick() }> ← Back</a>
                    <ul id=#gamesList></ul>
                </ul>
                <ul id=#create class="hidden">
                    <a class="back" onclick={ _ -> create_back_onclick() }> ← Back</a>
                    <li>
                        <input id=#name type="text" placeholder="Name of game" onnewline={_ -> create_game_onclick() }/>
                        <a class="button" onclick={ _ -> create_game_onclick() }>Create</a>
                    </li>
                </ul>
                <div id=#main>
                    <ul id=#menu>
                        <li><a class="button" onclick={_ -> menu_create_a_game_onclick() }>Create a game</a></li>
                        <li><a class="button" onclick={_ -> menu_join_a_game_onclick() }>Join a game</a></li>
                        <li><a class="button" onclick={_ -> User.logout()}>Logout</a></li>
                    </ul>
                    <ul id="chat_messages" onready={_ -> Network.add_callback(user_update, room)}></ul>
                    <input id=#entry onnewline={_ -> broadcast(author)} placeholder="Message..." />
                    <div class="button" onclick={_ -> broadcast(author)}>Post</>
                </div>
            </form>
        </div>
        </div>
    )
), login())

/* Message received about the state of the game. */
@client message_recieved(msg: message) = 
    match msg with 
        | { joining = user } -> Dom.hide(#waiting)
        | { state   = board } ->
            do Board.update(board)
            do Dom.transform([#color_of_current_player <- colorc_to_string(board.current_color)])
            if Option.get(Game.get_state()).color == board.current_color then
                Dom.hide(#waiting)
            else
                do Dom.select_raw("#waiting h1") |> Dom.set_text(_, "Waiting for " ^ colorc_to_string(board.current_color))
                Dom.show(#waiting)

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
                        <div onready={_ -> when_ready(name,color) }>
                            {Template.parse(Template.default, @static_content("resources/board.xmlt")()) |> Template.to_xhtml(Template.default, _)}
                        </div>

                    if (Option.get(game.white) == user) then 
                        Resource.styled_page("Chess", style, xml({white}))
                    else 
                        Resource.styled_page("Chess", style, xml({black}))
                ) 
                | {none}  -> fourOfour()
        )
        | {unlogged} -> fourOfour() //Shouldn't be able to happen here as we checked in the routing.
)

/*
    {Routing logic}
*/

login_required( page: -> resource ) = 
    if User.is_logged_in() then page() else login()


start(uri) = 
    match uri with
        | { path = [] ... }           -> login_required( -> lobby() )
        | { path = ["login"] ... }    -> login()
        | { path = ["signup"] ...}    -> singup()
        | { path = ["game",x|xs] ...} -> login_required( -> boardgame(x) )
        | { path = x ...}             -> fourOfour()


/**
 * Statically embed a bundle of resources
 */
server = Server.of_bundle([@static_include_directory("resources")])

/**
 * Launch the [start] dispatcher
 */
server = Server.simple_dispatch(start)