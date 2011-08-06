// 
//  chess.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-07-31.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

import stdlib.web.template
import stdlib.core.map

/*
    {Types}
*/

type kind      = {king} / {queen} / {rook} / {bishop} / {knight} / {pawn}
type colorC    = {white} / {black}
type piece     = {kind: kind ; color: colorC}
type position  = {letter: string ; number: int ; piece: option(piece) }
type board     = {positions: stringmap(intmap(position))}
type direction = {left_up} / {left_down} / {right_up} / {right_down}

/*
    {Communication}
*/

@publish game = Network.cloud("game") : Network.network(board)

message_recieved(b: board) = 
    // do Dom.set_text(Dom.select_id("player"),colorc_to_string(m.next_player))
    Board.update(b)

start() = 
    <div onready={_ -> Network.add_callback(message_recieved, game)}>
    <div onready={_ -> Board.prepare(Board.create()) }>
        {Template.parse(Template.default, @static_content("resources/board.xmlt")()) |> Template.to_xhtml(Template.default, _)}
    </div>
    </div>

/*
    {Misc functions}
*/

colorc_to_string = 
    | {white} -> "white"
    | {black} -> "black"

kind_to_string = 
    | {king}   -> "king"
    | {queen}  -> "queen"
    | {rook}   -> "rook"
    | {bishop} -> "bishop"
    | {knight} -> "knight"
    | {pawn}   -> "pawn"

domToList(dom: dom): list(dom) = Dom.fold( dom,acc -> [dom|acc], [], dom) |> List.rev(_)

duplicate(x, xs) = match x with
    | 0 -> xs
    | x -> duplicate(x-1,List.append(xs,xs))

create_string_map(xs: list((string,'a))): stringmap('a) = 
    List.fold( tuple,map -> StringMap_add(tuple.f1,tuple.f2,map),xs,StringMap_empty)

create_int_map(xs: list((int,'a))): intmap('a) = 
    List.fold( tuple,map -> IntMap_add(tuple.f1,tuple.f2,map),xs,IntMap_empty)

next_char(letter: string): string = 
    Char.of_string(letter) |> c -> int_of_char(c) |> x -> Char.unsafe_chr(x+1) |> Char.to_string(_)
    

/*
    {Board module}
*/

Board = {{
    
    user_color = {white}
        
    @private fields_iteri(fs: list('a),board): void = 
        Dom.select_raw("tr") |> Dom.sub(_,1,9) |> domToList(_) |> List.rev(_) |> List.iteri(rowi,tr -> 
            Dom.select_children(tr) |> Dom.sub(_,1,9) |> domToList(_) |> List.iteri(columi, td -> 
                List.iter( f -> f(rowi+1,columi+1,td,board), fs) // adding +1 because the indexes are 0-based
            ,_)
        ,_)
        
    prepare(board: board): void = 
        do fields_iteri([colorize(_,_,_,_), labelize(_,_,_,_), add_on_click_events(_,_,_,_)], board)
        do place_pieces(board)
        void        

    place_pieces(board: board) = 
        do Dom.select_raw("td img") |> Dom.remove(_)
        do Map.To.val_list(board.positions) |> List.iter(column ->  
            Map.To.val_list(column) |> List.iter(pos -> 
                Option.iter( piece -> 
                    img = Dom.of_xhtml(<img src="/resources/{kind_to_string(piece.kind)}_{colorc_to_string(piece.color)}.png" />)
                    do Position.select_position(pos) |> Dom.put_inside(_,img)
                    void
                ,pos.piece)
            ,_)
        ,_)
        void

    update(board: board) =  
        place_pieces(board)
        

    piece_at(row,column,board): option(position) =
        column_letter = Char.unsafe_chr(column+64) |> Char.to_string(_)
        Map.get(column_letter, board.positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_) |> pos ->
            match pos with 
                | { piece = { some = {color = color kind = kind}} ...} -> if color == user_color then { some = pos } else {none}
                | _ -> {none}
        
    add_on_click_events(row,column,td,board: board): void = 
        do Dom.bind(td, {click}, (_ -> 
                        
            movable = piece_at(row,column,board)
            
            if Option.is_some(movable) then 
                do Dom.select_raw("td.movable")  |> Dom.remove_class(_,"movable")
                do Dom.select_raw("td.selected") |> Dom.remove_class(_,"selected")
                do Dom.add_class(td, "selected")
                pos = Option.get(movable)
                highlight_possible_movements(pos, Option.get(pos.piece))
            else if Dom.has_class(td,"movable") then 
                posFrom = Dom.select_raw("td.selected") |> Position.position_from_dom(_, board)
                posTo = Position.position_from_dom(td, board)
                do Dom.select_raw("td.movable")  |> Dom.remove_class(_,"movable")
                do Dom.select_raw("td.selected") |> Dom.remove_class(_,"selected")
                newBoard = move(posFrom, posTo, board)
                do Network.broadcast(newBoard, game)
                void
            else 
                void
        ))
        void
    
    highlight_possible_movements(pos: position, piece: piece): void = 
        do Position.movable_positions(pos,piece,user_color) |> List.iter(pos -> 
            movable = Position.select_position(pos)
            Dom.add_class(movable,"movable")
        ,_)
        void
            
    labelize(row,column,td,board): void = 
        Dom.add_class(td, (Char.unsafe_chr(column+64) |> Char.to_string(_)) ^ Int.to_string(row)) 
    
    colorize(row,column,td,board): void = 
        if (mod(row,2) == 0) then 
            if mod(column,2) == 0 then Dom.add_class(td, "black") else Dom.add_class(td, "white") 
        else 
            if mod(column,2) == 0 then Dom.add_class(td, "white") else Dom.add_class(td, "black")

    move(posFrom, posTo, board): board = 
        // remove the old piece
        positions = Map.replace(posFrom.letter, rows -> (
            Map.replace(posFrom.number, (oldPos -> { oldPos with piece = {none}}), rows)
        ), board.positions)
        // place the new piece 
        positions2 = Map.replace(posTo.letter, rows -> (
            Map.replace(posTo.number, (oldPos -> { oldPos with piece = posFrom.piece}), rows)
        ), positions)
        { board with positions = positions2}
        
    
    create() = { positions = 
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
    }
}}

/*
    {Position module}
*/

Position = {{

    position_from_dom(dom: dom, board): position = 
        // Very hacky. The 7th and 8th chars are the colulm and row number.
        clz    = Dom.get_property(dom,"class") |> Option.get(_)
        column = String.get(6, clz)
        row    = String.get(7, clz) |> String.to_int(_)
        Map.get(column, board.positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_)

    select_position(pos: position): dom = 
        Dom.select_raw("." ^ pos.letter ^ Int.to_string(pos.number))
        
    movable_positions(pos: position, piece: piece, user_color: colorC): list(position) =    
        
        xs = match piece.kind with
            | {king}   -> 
                [right(pos,1),left(pos,1),up(pos,1),down(pos,1),
                 right(pos,1) |> Option.bind( p -> up(p,1) ,_),
                 right(pos,1) |> Option.bind( p -> down(p,1) ,_),
                 left(pos,1) |> Option.bind( p -> up(p,1) ,_),
                 left(pos,1) |> Option.bind( p -> down(p,1) ,_)]
            | {queen}  -> 
                (diagonal({left_up},pos)  ++ diagonal({left_down},pos) ++ 
                 diagonal({right_up},pos) ++ diagonal({right_down},pos) ++
                 right_inclusive(pos,7)   ++ left_inclusive(pos,7) ++
                 up_inclusive(pos,7)      ++ down_inclusive(pos,7)) |> 
                List.map( x -> { some = x}, _)
            | {rook}   ->
                List.flatten([
                    right_inclusive(pos,7),
                    left_inclusive(pos,7),
                    up_inclusive(pos,7),
                    down_inclusive(pos,7)]) |> 
                List.map( x -> { some = x}, _)
            | {bishop} -> 
                List.flatten([
                    diagonal({left_up},pos),
                    diagonal({left_down},pos),
                    diagonal({right_up},pos),
                    diagonal({right_down},pos)]) |> 
                List.map( x -> { some = x}, _)
            | {knight} -> 
                [right(pos,1) |> Option.bind( p -> down(p,2),_),
                 right(pos,1) |> Option.bind( p -> up(p,2),_),
                 left(pos,1) |> Option.bind(p -> down(p,2),_),
                 left(pos,1) |> Option.bind(p -> up(p,2),_),
                 up(pos,1) |> Option.bind( p -> left(p,2),_),
                 up(pos,1) |> Option.bind( p -> right(p,2),_),
                 down(pos,1) |> Option.bind(p -> left(p,2),_),
                 down(pos,1) |> Option.bind(p -> right(p,2),_)]
            | {pawn}   -> 
                if user_color == {white} then
                    if pos.number == 2 then
                        up_inclusive(pos,2) |> List.map( x -> { some = x}, _)
                    else
                        [up(pos,1)]
                else 
                    if pos.number == 7 then
                        down_inclusive(pos,2) |> List.map( x -> { some = x}, _)
                    else
                        [down(pos,1)]                    
        List.filter_map( x -> x , xs)
    
    /*
        Helper functions. 
    */
    
    @private right(pos,i): option(position) = 
        x = Char.of_string(pos.letter) |> c -> int_of_char(c) 
        l = Char.unsafe_chr(x+i) |> Char.to_string(_)
        if (x+i) > 72 then {none} else {some = {pos with letter = l}}
    
    @private left(pos,i): option(position) = 
        x = Char.of_string(pos.letter) |> c -> int_of_char(c) 
        l = Char.unsafe_chr(x-i) |> Char.to_string(_)
        if (x-i) < 65 then {none} else {some = {pos with letter = l}}
            
    @private up(pos,i): option(position) =             
        if (pos.number + i) > 8 then {none} else {some = {pos with number = pos.number+i}}
                                                     
    @private down(pos,i): option(position) =        
        if (pos.number - i) < 1 then {none} else {some = {pos with number = pos.number-i}}

    @private right_inclusive(pos: position,i: int): list(position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match right(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i-1,[p|acc])
        r(pos,i,[])

    @private left_inclusive(pos: position,i: int): list(position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match left(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i+1,[p|acc])
        r(pos,i,[])

    @private up_inclusive(pos: position,i: int): list(position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match up(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i-1,[p|acc])
        r(pos,i,[])
        
    @private down_inclusive(pos: position,i: int): list(position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match down(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i+1,[p|acc])
        r(pos,i,[])

    @private diagonal(direction: direction, pos: position): list(position) = 
        rec r(pos: position,i,acc) = match i with
            | 0 -> acc
            | x -> 
                p = match direction with
                    | {left_up}    -> up(pos,1) |> Option.bind( p -> left(p,1),_)
                    | {left_down}  -> down(pos,1) |> Option.bind( p-> left(p,1),_)
                    | {right_up}   -> up(pos,1) |> Option.bind( p -> right(p,1),_) 
                    | {right_down} -> down(pos,1) |> Option.bind( p -> left(p,1),_)
                match p with 
                    | {none} -> acc
                    | {some = p} -> r(p,i-1,[p|acc])
        r(pos,7,[])
}}


/*
    {Start the ting}
*/
    
server = Server.one_page_bundle("Chess",[@static_resource_directory("resources")],["resources/style.css"], start)