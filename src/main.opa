// 
//  main.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-06.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

/* {Routing logic} */

login_required( page: -> resource ) = 
    if User.is_logged_in() then page() else User.login_view()

start(uri) = 
    match uri with
        | { path = [] ... }            -> login_required( -> Page.main() )
        | { path = ["login"] ... }     -> User.login_view()
        | { path = ["signup"] ...}     -> User.signup_view()
        | { path = ["game",x|_] ...}   -> login_required( -> Game.game_view(x) )
        | { path = ["user", x|_] ...}  -> User.withUserNamed(x, User.page_view(_), Page.fourOfour)
        | { ... }                      -> Page.fourOfour()


/* Statically embed a bundle of resources */
server = Server.of_bundle([@static_include_directory("resources")])

/* Launch the [start] dispatcher */
server = Server.simple_dispatch(start)