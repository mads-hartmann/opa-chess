// 
//  chess.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-07-31.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

import stdlib.web.template
import stdlib.core.map

type kind      = {king} / {queen} / {rook} / {bishop} / {knight} / {pawn}
type colorC    = {white} / {black}
type piece     = {kind: kind ; color: colorC}
type position  = {letter: string ; number: int ; piece: option(piece) }
type board     = {positions: stringmap(intmap(position))}
type direction = {left_up} / {left_down} / {right_up} / {right_down}

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

select_position(pos: position): dom = 
    Dom.select_raw("." ^ pos.letter ^ Int.to_string(pos.number))

next_char(letter: string): string = 
    Char.of_string(letter) |> c -> int_of_char(c) |> x -> Char.unsafe_chr(x+1) |> Char.to_string(_)
    
    
Board = {{
    
    user_color = {white}
    
    init(board: board) = 
        <div onready={ _ -> prepare(board) }>
            {Template.parse(Template.default, @static_content("resources/board.xmlt")()) |> Template.to_xhtml(Template.default, _)}
        </div>
    
    @private fields_iteri(fs: list('a),board): void = 
        Dom.select_raw("tr") |> Dom.sub(_,1,9) |> domToList(_) |> List.rev(_) |> List.iteri(rowi,tr -> 
            Dom.select_children(tr) |> Dom.sub(_,1,9) |> domToList(_) |> List.iteri(columi, td -> 
                List.iter( f -> f(rowi+1,columi+1,td,board), fs) // adding +1 because the indexes are 0-based
            ,_)
        ,_)
        
    @private prepare(board: board): void = 
        do fields_iteri([colorize(_,_,_,_), labelize(_,_,_,_), add_on_click_events(_,_,_,_)], board)
        do Map.To.val_list(board.positions) |> List.iter(column ->  
            Map.To.val_list(column) |> List.iter(pos -> 
                Option.iter( piece -> 
                    img = Dom.of_xhtml(<img src="/resources/{kind_to_string(piece.kind)}_{colorc_to_string(piece.color)}.png" />)
                    do select_position(pos) |> Dom.put_inside(_,img)
                    void
                ,pos.piece)
            ,_)
        ,_)
        void        

    add_on_click_events(row,column,td,board: board): void = 
        do Dom.bind(td, {click}, (_ -> 
            column_letter = Char.unsafe_chr(column+64) |> Char.to_string(_)
            Map.get(column_letter, board.positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_) |> pos ->
                match pos with 
                    | { piece = { some = {color = color kind = kind}} ...} -> if color == user_color then
                        do Dom.select_raw("td.movable") |> Dom.remove_class(_,"movable")
                        do Dom.select_raw("td.selected") |> Dom.remove_class(_, "selected")
                        do Dom.add_class(td, "selected")
                        highlight_possible_movements(pos, Option.get(pos.piece)) // safe. Already checked by pattern matching
                    | _ -> void 
        ))
        void
    
    highlight_possible_movements(pos: position, piece: piece): void = 
        do movable_positions(pos,piece) |> List.iter(pos -> 
            movable = select_position(pos)
            do Dom.add_class(movable,"movable")
            do Dom.bind(movable, {click}, (_ -> 
                do Dom.select_raw(".selected img") |> Dom.put_inside(movable,_)
                void
            ))
            void
        ,_)
        void
            
        
    movable_positions(pos: position, piece: piece): list(position) =    
        
        pos_add_column(pos,i): option(position) = 
            x = Char.of_string(pos.letter) |> c -> int_of_char(c) 
            l = Char.unsafe_chr(x+i) |> Char.to_string(_)
            if (x+i) > 72 then {none} else {some = {pos with letter = l}}
        
        pos_subtract_column(pos,i): option(position) = 
            x = Char.of_string(pos.letter) |> c -> int_of_char(c) 
            l = Char.unsafe_chr(x-i) |> Char.to_string(_)
            if (x-i) < 65 then {none} else {some = {pos with letter = l}}
                
        pos_add_row(pos,i): option(position) =             
            if (pos.number + i) > 8 then {none} else {some = {pos with number = pos.number+i}}
                                                         
        pos_subtract_row(pos,i): option(position) =        
            if (pos.number - i) < 1 then {none} else {some = {pos with number = pos.number-i}}

        pos_add_column_inclusive(pos: position,i: int): list(position) =
            rec r(pos,i,acc) = match i with
                | 0 -> acc
                | x -> match pos_add_column(pos,1) with
                    | {none} -> acc // fail fast. can't jump over 
                    | {some = p} -> r(p,i-1,[p|acc])
            r(pos,i,[])
    
        pos_subtract_column_inclusive(pos: position,i: int): list(position) =
            rec r(pos,i,acc) = match i with
                | 0 -> acc
                | x -> match pos_subtract_column(pos,1) with
                    | {none} -> acc // fail fast. can't jump over 
                    | {some = p} -> r(p,i+1,[p|acc])
            r(pos,i,[])

        pos_add_row_inclusive(pos: position,i: int): list(position) =
            rec r(pos,i,acc) = match i with
                | 0 -> acc
                | x -> match pos_add_row(pos,1) with
                    | {none} -> acc // fail fast. can't jump over 
                    | {some = p} -> r(p,i-1,[p|acc])
            r(pos,i,[])
            
        pos_subtract_row_inclusive(pos: position,i: int): list(position) =
            rec r(pos,i,acc) = match i with
                | 0 -> acc
                | x -> match pos_subtract_row(pos,1) with
                    | {none} -> acc // fail fast. can't jump over 
                    | {some = p} -> r(p,i+1,[p|acc])
            r(pos,i,[])
    
        pos_diagonal(direction: direction, pos: position): list(position) = 
            rec r(pos: position,i,acc) = match i with
                | 0 -> acc
                | x -> 
                    p = match direction with
                        | {left_up}    -> pos_add_row(pos,1) |> Option.bind( p -> pos_subtract_column(p,1),_)
                        | {left_down}  -> pos_subtract_row(pos,1) |> Option.bind( p-> pos_subtract_column(p,1),_)
                        | {right_up}   -> pos_add_row(pos,1) |> Option.bind( p -> pos_add_column(p,1),_) 
                        | {right_down} -> pos_subtract_row(pos,1) |> Option.bind( p -> pos_subtract_column(p,1),_)
                    match p with 
                        | {none} -> acc
                        | {some = p} -> r(p,i-1,[p|acc])
            r(pos,7,[])
    
        xs = match piece.kind with
            | {king}   -> 
                [pos_add_column(pos,1),
                 pos_subtract_column(pos,1),
                 pos_add_row(pos,1),
                 pos_subtract_row(pos,1),
                 pos_add_column(pos,1) |> Option.bind( p -> pos_add_row(p,1) ,_),
                 pos_add_column(pos,1) |> Option.bind( p -> pos_subtract_row(p,1) ,_),
                 pos_subtract_column(pos,1) |> Option.bind( p -> pos_add_row(p,1) ,_),
                 pos_subtract_column(pos,1) |> Option.bind( p -> pos_subtract_row(p,1) ,_)]
            | {queen}  -> List.flatten([
                    pos_diagonal({left_up},pos),
                    pos_diagonal({left_down},pos),
                    pos_diagonal({right_up},pos),
                    pos_diagonal({right_down},pos),
                    pos_add_column_inclusive(pos,7),
                    pos_subtract_column_inclusive(pos,7),
                    pos_add_row_inclusive(pos,7),
                    pos_subtract_row_inclusive(pos,7)
                ]) |> 
                List.map( x -> { some = x}, _)
            | {rook}   ->
                List.flatten([
                    pos_add_column_inclusive(pos,7),
                    pos_subtract_column_inclusive(pos,7),
                    pos_add_row_inclusive(pos,7),
                    pos_subtract_row_inclusive(pos,7)]) |> 
                List.map( x -> { some = x}, _)
            | {bishop} -> 
                List.flatten([
                    pos_diagonal({left_up},pos),
                    pos_diagonal({left_down},pos),
                    pos_diagonal({right_up},pos),
                    pos_diagonal({right_down},pos)]) |> 
                List.map( x -> { some = x}, _)
            | {knight} -> 
                [pos_add_column(pos,1) |> Option.bind( p -> pos_subtract_row(p,2),_),
                 pos_add_column(pos,1) |> Option.bind( p -> pos_add_row(p,2),_),
                 pos_subtract_column(pos,1) |> Option.bind(p -> pos_subtract_row(p,2),_),
                 pos_subtract_column(pos,1) |> Option.bind(p -> pos_add_row(p,2),_),
                 pos_add_row(pos,1) |> Option.bind( p -> pos_subtract_column(p,2),_),
                 pos_add_row(pos,1) |> Option.bind( p -> pos_add_column(p,2),_),
                 pos_subtract_row(pos,1) |> Option.bind(p -> pos_subtract_column(p,2),_),
                 pos_subtract_row(pos,1) |> Option.bind(p -> pos_add_column(p,2),_)]
            | {pawn}   -> 
                if user_color == {white} then
                    if pos.number == 2 then
                        pos_add_row_inclusive(pos,2) |> List.map( x -> { some = x}, _)
                    else
                        [pos_add_row(pos,1)]
                else 
                    if pos.number == 7 then
                        pos_subtract_row_inclusive(pos,2) |> List.map( x -> { some = x}, _)
                    else
                        [pos_subtract_row(pos,1)]                    
        List.filter_map( x -> x , xs)

    labelize(row,column,td,board): void = 
        Dom.add_class(td, (Char.unsafe_chr(column+64) |> Char.to_string(_)) ^ Int.to_string(row)) 
    
    colorize(row,column,td,board): void = 
        if (mod(row,2) == 0) then 
            if mod(column,2) == 0 then Dom.add_class(td, "black") else Dom.add_class(td, "white") 
        else 
            if mod(column,2) == 0 then Dom.add_class(td, "white") else Dom.add_class(td, "black")
    
    
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


start() = Board.init(Board.create())
    
server = Server.one_page_bundle("Chess",[@static_resource_directory("resources")],["resources/style.css"], start)
