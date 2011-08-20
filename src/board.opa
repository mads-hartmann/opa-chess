// 
//  chess.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-07-31.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

import stdlib.web.template
import stdlib.core.map
import stdlib.core

/*
    {Board module}
*/

type board = {
    chess_positions: stringmap(intmap(chess_position))
    current_color: colorC
}

Board = {{
    
    /*
        User-specific information related to one specific board. The color of the current 
        user and the channel to use. 
    */
    user_color()    = Option.get(Game.get_state()).color
    opposite_color() = match user_color() with 
        | {white} -> {black}
        | {black} -> {white}
    channel()       = Option.get(Game.get_state()).channel
        
    prepare(board: board): void = 
    (
        do iteri(board, [colorize(_,_,_,_), labelize(_,_,_,_)])
        do place_pieces(board)
        do update_counters(board)
        void
    )

    place_pieces(board: board) = 
    (
        do Dom.select_raw("td img") |> Dom.remove(_)
        do Map.To.val_list(board.chess_positions) |> List.iter(column ->  
            Map.To.val_list(column) |> List.iter(pos -> 
                Option.iter( piece -> 
                    img = Dom.of_xhtml(<img src="/resources/{kind_to_string(piece.kind)}_{colorc_to_string(piece.color)}.png" />)
                    do Position.select_chess_position(pos) |> Dom.put_inside(_,img)
                    void
                ,pos.piece)
            ,_)
        ,_)
        do iteri(board, [unbind])
        do iteri(board, [add_on_click_events(_,_,_,_)])
        void
    )

    update(board: board) = 
    (
        do place_pieces(board)
        do update_counters(board)
        if opposite_king_is_dead(board) then (
            Dom.set_text(#status, "You've won!")
        ) else if your_king_is_dead(board) then (
            Dom.set_text(#status, "You've lost!")
        )
        else void
    )
    
    opposite_king_is_dead(board: board): bool = 
    (
        Map.To.val_list(board.chess_positions) 
            |> List.collect(Map.To.val_list(_),_) 
            |> List.fold(pos,acc -> (
                match pos.piece with
                    | { some = {color = c kind = {king}}} -> if c != user_color() then false else acc
                    | _ -> acc
            ), _, true)
    )
    
    your_king_is_dead(board): bool = 
    (
        Map.To.val_list(board.chess_positions) 
            |> List.collect(Map.To.val_list(_),_) 
            |> List.fold(pos,acc -> (
                match pos.piece with
                    | { some = {color = c kind = {king}}} -> if c == user_color() then false else acc
                    | _ -> acc
            ), _, true)        
    )
    
    update_counters(board: board) = 
    (
        (blacks,whites) = Map.To.val_list(board.chess_positions) 
            |> List.collect(Map.To.val_list(_),_) 
            |> List.fold(pos,acc -> (
                    (whites,blacks) = acc
                    match pos.piece with
                        | { some = ~{color kind}} -> if color == {white} then (whites+1,blacks) else (whites,blacks+1)
                        | {none} -> acc
               ), _, (0,0)) 
        do Dom.set_text(#black_left, Int.to_string(blacks))
        do Dom.set_text(#white_left, Int.to_string(whites))
        void
    )
    
    /* 
     * Given a row, column, board it will return some with a chess position if there is a 
     * piece at the position _and_ it's of the proper color 
     */    
    piece_at(row,column,board): option(chess_position) =
    (
        column_letter = Column.from_int(column+64)
        Map.get(column_letter, board.chess_positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_) |> pos ->
            match pos with 
                | { piece = { some = {color = color kind = kind}} ...} -> if color == user_color() then { some = pos } else {none}
                | _ -> {none}
    )
    
    /*
     *
     */
    has_piece_of_own_color(board: board, row: int, column: string): bool = 
    (
        Map.get(column, board.chess_positions)
            |> Option.get(_) 
            |> Map.get(row, _) 
            |> Option.get(_) 
            |> pos -> match pos with 
                | { piece = { some = {color = color kind = kind}} ...} -> color == user_color()
                | _ -> false
    )
    
    has_piece_of_opposite_color(board: board, row: int, column: string): bool = 
    (
        Map.get(column, board.chess_positions)
            |> Option.get(_)
            |> Map.get(row,_)
            |> Option.get(_)
            |> pos -> match pos with
                | { piece = { some = {color = color kind = kind}} ...} -> color != user_color()
                | _ -> false
    )

    unbind(row,column,td,board): void = Dom.unbind_event(td,{click})
        
    add_on_click_events(row,column,td,board: board): void = 
    (
        do Dom.bind(td, {click}, (_ -> 
            movable = piece_at(row,column,board)
            if board.current_color == user_color() then 
            (
                 if Option.is_some(movable) then 
                 (
                     pos = Option.get(movable)
                     do Dom.select_raw("td.movable")  |> Dom.remove_class(_,"movable")
                     do Dom.select_raw("td.selected") |> Dom.remove_class(_,"selected")
                     do Dom.add_class(td, "selected")
                     highlight_possible_movements(board, pos, Option.get(pos.piece))
                 ) else if Dom.has_class(td,"movable") then 
                 (
                    posFrom  = Dom.select_raw("td.selected") |> Position.chess_position_from_dom(_, board)
                    posTo    = Position.chess_position_from_dom(td, board)
                    newBoard = move(posFrom, posTo, board) 
                    do Dom.select_raw("td.movable")  |> Dom.remove_class(_,"movable")
                    do Dom.select_raw("td.selected") |> Dom.remove_class(_,"selected")
                    do Network.broadcast({ state = newBoard},channel()) 
                    void
                ) else void
            ) else void 
        ))
        void
    )
    
    highlight_possible_movements(board: board, pos: chess_position, piece: piece): void = 
    (
        do Position.movable_chess_positions(pos,piece,user_color(),board) |> List.iter(pos -> 
            movable = Position.select_chess_position(pos)
            Dom.add_class(movable,"movable")
        ,_)
        void
    )
            
    labelize(row,column,td,board): void = 
        Dom.add_class(td, Column.from_int(column+64) ^ Int.to_string(row)) 
    
    colorize(row,column,td,board): void = 
    (
        if (mod(row,2) == 0) then 
            if mod(column,2) == 0 then Dom.add_class(td, "black") else Dom.add_class(td, "white") 
        else 
            if mod(column,2) == 0 then Dom.add_class(td, "white") else Dom.add_class(td, "black")
    )
    
    move(posFrom, posTo, board): board = 
    (
        next_color = match board.current_color with 
            | {white} -> {black}
            | {black} -> {white}
        // remove the old piece
        chess_positions = Map.replace(posFrom.letter, rows -> (
            Map.replace(posFrom.number, (oldPos -> { oldPos with piece = {none}}), rows)
        ), board.chess_positions)
        // place the new piece 
        chess_positions2 = Map.replace(posTo.letter, rows -> (
            Map.replace(posTo.number, (oldPos -> { oldPos with piece = posFrom.piece}), rows)
        ), chess_positions)
        { chess_positions = chess_positions2 current_color = next_color }
     )
    
    /* 
        Method for applying a list of functions on every td dom element in the board. 
    */
    iteri(board, xs: list(int,int,dom,board -> void)): void = 
    (
        do Dom.select_raw("tr") |> domToList(_) |> List.rev(_) |> List.iteri(rowi,tr -> 
            Dom.select_children(tr) |> domToList(_) |> List.iteri(columi, td -> 
                do List.iter(f -> f(rowi+1,columi+1,td,board),xs)
                void
            ,_)
        ,_)
        void
    )
    
    create() = 
    { 
        current_color = {white} 
        chess_positions = (
            columns = ["A","B","C","D","E","F","G","H"] 
            rows = duplicate(8,[8,7,6,5,4,3,2,1])
            List.map( column -> (column, 
                List.map( row -> (row, 
                    pos = { letter = column number = row piece = {none}}
                    match (column, row) with
                        | ("A",8) -> {pos with piece = some({ kind = {rook}   color = {black} })}
                        | ("B",8) -> {pos with piece = some({ kind = {knight} color = {black} })}
                        | ("C",8) -> {pos with piece = some({ kind = {bishop} color = {black} })}
                        | ("D",8) -> {pos with piece = some({ kind = {king}   color = {black} })}
                        | ("E",8) -> {pos with piece = some({ kind = {queen}  color = {black} })}
                        | ("F",8) -> {pos with piece = some({ kind = {bishop} color = {black} })}
                        | ("G",8) -> {pos with piece = some({ kind = {knight} color = {black} })}
                        | ("H",8) -> {pos with piece = some({ kind = {rook}   color = {black} })}
                        | (_,7)   -> {pos with piece = some({ kind = {pawn}   color = {black} })}
                        | (_,2)   -> {pos with piece = some({ kind = {pawn}   color = {white} })}
                        | ("A",1) -> {pos with piece = some({ kind = {rook}   color = {white} })}
                        | ("B",1) -> {pos with piece = some({ kind = {knight} color = {white} })}
                        | ("C",1) -> {pos with piece = some({ kind = {bishop} color = {white} })}
                        | ("D",1) -> {pos with piece = some({ kind = {king}   color = {white} })}
                        | ("E",1) -> {pos with piece = some({ kind = {queen}  color = {white} })}
                        | ("F",1) -> {pos with piece = some({ kind = {bishop} color = {white} })}
                        | ("G",1) -> {pos with piece = some({ kind = {knight} color = {white} })}
                        | ("H",1) -> {pos with piece = some({ kind = {rook}   color = {white} })}
                        | (_,_)   -> pos
                ),rows) |> create_int_map(_)
            ),columns) |> create_string_map(_)
        )
    }
}}