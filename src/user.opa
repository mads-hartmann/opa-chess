// 
//  user.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-06.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess.user

import chess.types
import stdlib.web.client

db /user: stringmap(option(user))
db /user[_] = none

User = {{
    
    state = UserContext.make({unlogged} : User.status)

    get_status() = 
        UserContext.execute((a -> a), state)

    is_logged_in() = match get_status() with 
        | ~{user} -> true 
        | {unlogged} -> false 
    
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
    
    create(username, email, password): outcome(user, list(string)) = 
        match /user[username] with 
            | {some = user} -> { failure = ["A user with that username already exists"] }
            | {none} -> (
                validator(c,a) = if String.is_empty(c.value) then [c.label ^ " is required"|a] else a
                xs = [
                    { value = username label = "username" },
                    { value = email label = "email" },
                    { value = password label = "password" }
                ]
                match List.fold(validator, xs, []) with 
                    | [] -> 
                        u = { name = username email = email password = password }
                        do /user[username] <- Option.some(u)
                        do UserContext.change(( _ -> {user = u}), state)
                        { success = u }
                    | { hd = x tl = xs} -> { failure = [x|xs] }
            )
}}