// 
//  Chat.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-22.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

// The global chat network. 
@publish room = Network.cloud("room") : Network.network(chat_message)

type chat_message = { author : string ; text : string }

Chat = {{

    create(author: string) = create_with_channel(author, room)
    
    create_with_channel(author, channel) = 
    (
        user_update(x : chat_message) =
            line = <li>
                        <span class="user">{x.author}:</span>
                        {x.text}
                    </li>
            do Dom.transform([#chat_messages +<- line ])
            Dom.scroll_to_bottom(#chat_messages)

        broadcast() =
            do Network.broadcast({~author text=Dom.get_value(#entry)}, channel)
            Dom.clear_value(#entry)
        
        <div class="chat">
            <ul id="chat_messages" onready={_ -> Network.add_callback(user_update, channel)}></ul>
            <div class="input">
                <input id=#entry onnewline={_ -> broadcast()} placeholder="Message..." />
                <div class="button" onclick={_ -> broadcast()}>Post</>
            </div>
        </div>
    )

}}