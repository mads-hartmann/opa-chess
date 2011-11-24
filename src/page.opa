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

    header =
      <a href="http://github.com/mattgu74/OpaTetris">
        <img style="position: absolute; top: 0; right: 0; border: 0;"
          src="https://a248.e.akamai.net/assets.github.com/img/4c7dc970b89fd04b81c8e221ba88ff99a06c6b61/687474703a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f77686974655f6666666666662e706e67" alt="Fork me on GitHub"/>
      </>

    footer =
      <div class="footer">
        <span><a target="_blank" href="http://blog.opalang.org/2011/11/spotlight-on-opa-app-opachess-by.html">About the app</a></span> • 
        <span><a target="_blank" href="https://github.com/mads379/opa-chess">Fork on GitHub</a></span> • 
        <span><a target="_blank" href="https://opalang.org">Built with <img src="/resources/opa-logo-small.png" alt="Opa"/></a></span>
      </>
      <script src="http://opalang.org/google_analytics.js" />

    default(idOpt: option(string), content) = 
    (
        id = Option.default("", idOpt)
        Resource.styled_page("Chess", style,
          <>
            {Page.header}
            <div id="{id}" class="container">
                <div id="error_container" class="error_container no_errors">
                    <ul id="errors"></ul>
                </div>
                <div class="content">
                    {content}
                </div>
            </div>
            {Page.footer}
          </>
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
                | {success = _ } -> Client.goto("/game/" ^ name)
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
                |> List.filter( x -> Option.is_none(x.black), _) 
                |> List.iter( x -> Dom.transform([#gamesList +<- 
                        <li onclick={_ -> 
                            match Game.join(x.name, user) with 
                                | { success = _ } -> Client.goto("/game/" ^ x.name) 
                                | { failure = xs } -> Page.show_error(xs)
                        }>{x.name}</li>]),
                    _)

        Resource.styled_page("Chess", style,
          <>
            {header}
            <div id="lobby" class="container">
            <div id="error_container" class="error_container no_errors">
                <ul id="errors"></ul>
            </div>
            <div class="content">
                <form>
                    <div id=#join class="hidden">
                        <ul>
                            <a class="back" onclick={ _ -> join_back_onclick() }> ← Back</a>
                            <ul id=#gamesList></ul>
                        </ul>
                    </div>
                    <div id=#create class="hidden">
                        <ul>
                            <a class="back" onclick={ _ -> create_back_onclick() }> ← Back</a>
                            <li>
                                <span class="text"><input id=#name type="text" placeholder="Name of game" onnewline={_ -> create_game_onclick() }/></span>
                                <a class="button" onclick={ _ -> create_game_onclick() }><span class="inner">Create</span></a>
                            </li>
                        </ul>
                    </div>
                    <div id=#main>
                        <ul class="menu">
                            <li><a class="button" onclick={_ -> menu_create_a_game_onclick() }><span class="inner">Create a game</span></a></li>
                            <li><a class="button" onclick={_ -> menu_join_a_game_onclick() }><span class="inner">Join a game</span></a></li>
                            <li><a class="button" onclick={_ -> User.logout()}><span class="inner">Logout</span></a></li>
                        </ul>
                        { Chat.create(user.name) }
                    </div>
                </form>
            </div>
            </div>
            {footer}
          </>
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
