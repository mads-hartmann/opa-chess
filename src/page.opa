// 
//  page.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-22.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess



Page = {{

    style = ["/resources/style.css"]
    
    /*
        views
    */
    
    fourOfour() = default({ some = "fourofour"}, <h1>404</h1>)
    
    default(idOpt: option(string), content) = 
    (
        id = Option.default("", idOpt)
        Resource.styled_page("Chess", style,
            <div id="{id}" class="container">
                <div id="error_container" class="error_container no_errors">
                    <ul id="errors"></ul>
                </div>
                <div class="content">
                    {content}
                </div>
            </div>
        )
    )
    
    main() = User.withUser( user -> (

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
                | {failure = xs }   -> Page.show_error(xs)

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
                                | { failure = xs } -> Page.show_error(xs)
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
                        { Chat.create(user.name) }
                    </div>
                </form>
            </div>
            </div>
        )
    ), User.login_view())
    
    /*
        Actions 
    */
    
    show_error(xs: list(string)) = 
        do Dom.remove_class(#error_container,"no_errors")
        do Dom.add_class(#error_container,"has_errors")
        do Dom.remove_content(#errors)
        List.iter( x -> Dom.transform([#errors +<- <li>{x}</li>]), xs)
}}