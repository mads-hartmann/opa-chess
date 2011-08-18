// 
//  position.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-18.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

Position = {{

    chess_position_from_dom(dom: dom, board): chess_position = 
        // Very hacky. The 7th and 8th chars are the colulm and row number.
        clz    = Dom.get_property(dom,"class") |> Option.get(_)
        column = String.get(6, clz)
        row    = String.get(7, clz) |> String.to_int(_)
        Map.get(column, board.chess_positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_)

    select_chess_position(pos: chess_position): dom = 
        Dom.select_raw("." ^ pos.letter ^ Int.to_string(pos.number))
        
    movable_chess_positions(pos: chess_position, piece: piece, user_color: colorC): list(chess_position) = (
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
    )
    /*
        Helper functions. 
    */
    
    right(pos,i): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x+i)
        if (x+i) > 72 then {none} else {some = {pos with letter = l}}
    
    left(pos,i): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x-i)
        if (x-i) < 65 then {none} else {some = {pos with letter = l}}
            
    up(pos,i): option(chess_position) =             
        if (pos.number + i) > 8 then {none} else {some = {pos with number = pos.number+i}}
                                                     
    down(pos,i): option(chess_position) =        
        if (pos.number - i) < 1 then {none} else {some = {pos with number = pos.number-i}}

    right_inclusive(pos: chess_position,i: int): list(chess_position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match right(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i-1,[p|acc])
        r(pos,i,[])

    left_inclusive(pos: chess_position,i: int): list(chess_position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match left(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i+1,[p|acc])
        r(pos,i,[])

    up_inclusive(pos: chess_position,i: int): list(chess_position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match up(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i-1,[p|acc])
        r(pos,i,[])
        
    down_inclusive(pos: chess_position,i: int): list(chess_position) =
        rec r(pos,i,acc) = match i with
            | 0 -> acc
            | x -> match down(pos,1) with
                | {none} -> acc // fail fast. can't jump over 
                | {some = p} -> r(p,i+1,[p|acc])
        r(pos,i,[])

    diagonal(direction: direction, pos: chess_position): list(chess_position) = 
        rec r(pos: chess_position,i,acc) = match i with
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