// 
//  user.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-06.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

import stdlib.web.client

db /user: stringmap(option(user))
db /user[_] = none

type user = { 
    name: string ; 
    password: string 
    games: int; 
    wins: int; 
    losses: int; 
}

type User.status = { user: user } / { unlogged }

User = {{

    state = UserContext.make({unlogged} : User.status)

    /*
        Data related functions 
    */

    withUser(f: user -> 'a, otherwise: 'a) = match get_status() with
        | ~{user}    -> f(user)
        | {unlogged} -> otherwise

    withUserNamed(name, f: user -> 'a, otherwise: -> 'a) = 
        match /user[name] with
            | ~{some} -> f(some)
            | {none}-> otherwise()

    get_status() = 
        UserContext.execute((a -> a), state)

    is_logged_in() = match get_status() with 
        | {unlogged} -> false 
        | _ -> true
    
    login(username: string, password: string): bool = 
        match /user[username] with
            | {some = user } -> if user.password == password then 
                                    do UserContext.change(( _ -> {user = user}), state)
                                    true 
                                else 
                                    false
            | {none} -> false 
    
    logout(): void =
        do UserContext.change(( _ -> { unlogged }), state)
        Client.goto("/login")
    
    create(username, password): outcome(user, list(string)) = 
        match /user[username] with 
            | {none} -> (
                validator(c,a) = if String.is_empty(c.value) then [c.label ^ " is required"|a] else a
                xs = [
                    { value = username label = "username" },
                    { value = password label = "password" }
                ]
                match List.fold(validator, xs, []) with 
                    | [] -> 
                        u = { name     = username 
                              password = password 
                              games    = 0 
                              wins     = 0 
                              losses   = 0}
                        do /user[username] <- Option.some(u)
                        do UserContext.change(( _ -> {user = u}), state)
                        { success = u }
                    | { hd = x tl = xs} -> { failure = [x|xs] }
            )
            | _ -> { failure = ["A user with that username already exists"] }
    
    update(user): void = /user[user.name] <- { some = user }
    
    /*
        View related functions 
    */
    
    login_view() = 
    (
        attempt_login() = 
            username = Dom.get_value(#username)
            password = Dom.get_value(#password)
            match User.login(username, password) with 
                | {true}  -> Client.goto("/")
                | {false} -> 
                    do Page.show_error(["Wrong combination"])
                    Dom.give_focus(#username)

        Page.default({ some = "login"},
            <div id="login_box">
            <ul onready={ _ -> Dom.give_focus(#username) }>
                <li><span class="text"><input id=#username placeholder="Username"/></span></li>
                <li><span class="text"><input id=#password placeholder="Password" type="password" onnewline={ _ -> attempt_login() }/></span></li>
                <li>
                    <span class="button"><input type="submit" class="inner" value="Login" onclick={ _ -> attempt_login() } /></span>
                    <span class="button"><a class="inner" href="/signup">Signup</a></span>
                </li>
            </ul>
            </div>
        )
    )
    
    signup_view() = 
    (
        attempt_signup() = 
            username = Dom.get_value(#username)
            password = Dom.get_value(#password)
            match User.create(username, password) with 
                | {failure = failure } -> Page.show_error(failure)                            
                | _ -> Client.goto("/")
            
        Page.default( {some = "login"}, 
            <div id="login_box">
            <ul id="signup" onready={ _ -> Dom.give_focus(#username) }>
                <li>
                    <span class="text"><input id=#username placeholder="Username" type="text" /></span>
                </li>
                <li>
                    <span class="text"><input id=#password placeholder="Password" type="password" onnewline={ _ -> attempt_signup() }  /></span>
                </li>
                <li>
                    <span class="button">
                    <input type="submit" class="inner" value="Sign up" onclick={ _ -> attempt_signup() } />
                    </span>
                </li>
            </ul>
            </div>
        )
    )   
    
    page_view(user) = 
    (
        Page.default({ some = "user" },
            <div id="profile_page">
                <img src="/resources/pawn_rank.png" class="rank_image"/>
                <h1>{user.name}</h1>
                <h2>Rank: pawn</h2>
                <ul>
                    <li><h3>{user.games}</h3><span>Games</span></li>
                    <li><h3>{user.wins}</h3><span>Wins</span></li>
                    <li><h3>{user.losses}</h3><span>Losses</span></li>
                </ul>
            </div>
        )
    )
}}