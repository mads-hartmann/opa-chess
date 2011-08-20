// 
//  position.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-18.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

type chess_position = {letter: string ; number: int ; piece: option(piece) }

Position = {{

    chess_position_from_dom(dom: dom, board): chess_position = 
    (
        // Very hacky. The 7th and 8th chars are the colulm and row number.
        clz    = Dom.get_property(dom,"class") |> Option.get(_)
        column = String.get(6, clz)
        row    = String.get(7, clz) |> String.to_int(_)
        Map.get(column, board.chess_positions) |> Option.get(_) |> Map.get(row, _) |> Option.get(_)
    )
        
    select_chess_position(pos: chess_position): dom = 
        Dom.select_raw("." ^ pos.letter ^ Int.to_string(pos.number))
        
    movable_chess_positions(pos: chess_position, piece: piece, user_color: colorC, board: board): list(chess_position) = 
    (
        xs = match piece.kind with
            | {king}   -> 
                [right_option(pos,board,1),left_option(pos,board,1),up_option(pos,board,1),down_option(pos,board,1),
                 right(pos,board,1) |> Option.bind( p -> up_option(p,board,1) ,_),
                 right(pos,board,1) |> Option.bind( p -> down_option(p,board,1) ,_),
                 left(pos,board,1)  |> Option.bind( p -> up_option(p,board,1) ,_),
                 left(pos,board,1)  |> Option.bind( p -> down_option(p,board,1) ,_)]
            | {queen}  -> 
                (diagonal({left_up},pos,board)  ++ diagonal({left_down},pos,board) ++ 
                 diagonal({right_up},pos,board) ++ diagonal({right_down},pos,board) ++
                 left_inclusive(pos,board,7) ++
                 right_inclusive(pos,board,7)   ++ 
                 up_inclusive(pos,board,7)      ++ down_inclusive(pos,board,7)) |> 
                List.map( x -> { some = x}, _)
            | {rook}   ->
                List.flatten([
                    right_inclusive(pos,board,7),
                    left_inclusive(pos,board,7),
                    up_inclusive(pos,board,7),
                    down_inclusive(pos,board,7)]) |> 
                List.map( x -> { some = x}, _)
            | {bishop} -> 
                List.flatten([
                    diagonal({left_up},pos,board),
                    diagonal({left_down},pos,board),
                    diagonal({right_up},pos,board),
                    diagonal({right_down},pos,board)]) |> 
                List.map( x -> { some = x}, _)
            | {knight} -> 
                [right(pos,board,1) |> Option.bind( p -> down_option(p,board,2),_),
                 right(pos,board,1) |> Option.bind( p -> up_option(p,board,2),_),
                 left(pos,board,1) |> Option.bind(p -> down_option(p,board,2),_),
                 left(pos,board,1) |> Option.bind(p -> up_option(p,board,2),_),
                 up(pos,board,1) |> Option.bind( p -> left_option(p,board,2),_),
                 up(pos,board,1) |> Option.bind( p -> right_option(p,board,2),_),
                 down(pos,board,1) |> Option.bind(p -> left_option(p,board,2),_),
                 down(pos,board,1) |> Option.bind(p -> right_option(p,board,2),_)]
            | {pawn}   -> 
                if user_color == {white} then
                    if pos.number == 2 then
                        up_inclusive(pos,board,2) |> List.map( x -> { some = x}, _)
                    else
                        [up(pos,board,1)]
                else 
                    if pos.number == 7 then
                        down_inclusive(pos,board,2) |> List.map( x -> { some = x}, _)
                    else
                        [down(pos,board,1)]                    
        List.filter_map( x -> x , xs)
    )
    /*
        Helper functions. 
    */
     
     
    mov_opt(pos,board,i,f) =
        match f(pos,board,i) with
            | {none} -> {none}
            | ~{some} -> if Board.has_piece(board,some.number,some.letter) then {none} else {some = some}

    right_option(pos,board,i) = mov_opt(pos,board,i,right(_,_,_))
    left_option(pos,board,i) = mov_opt(pos,board,i,left(_,_,_))
    up_option(pos,board,i) = mov_opt(pos,board,i,up(_,_,_))
    down_option(pos,board,i) = mov_opt(pos,board,i,down(_,_,_))
        
    right(pos: chess_position,board: board,i: int): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x+i)
        next_pos = {pos with letter = l}
        if (x+i) > 72 then {none} else {some = next_pos}
    
    left(pos: chess_position,board: board,i: int): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x-i)
        next_pos = {pos with letter = l}
        if (x-i) < 65 then {none} else {some = next_pos}
            
    up(pos: chess_position,board: board,i: int): option(chess_position) = 
        next_pos = {pos with number = pos.number+i}
        if (pos.number + i) > 8 then {none} else {some = next_pos}
                                                     
    down(pos: chess_position,board: board,i: int): option(chess_position) = 
        next_pos = {pos with number = pos.number-i}
        if (pos.number - i) < 1 then {none} else {some = next_pos}

    right_inclusive(pos: chess_position,board: board,i: int): list(chess_position) =
        inclusive(pos,i,board,right_option(_,_,_),[])

    left_inclusive(pos: chess_position,board: board,i: int): list(chess_position) =
        inclusive(pos,i,board,left_option(_,_,_),[])

    up_inclusive(pos: chess_position,board: board,i: int): list(chess_position) =
        inclusive(pos,i,board,up_option(_,_,_),[])
        
    down_inclusive(pos: chess_position,board: board,i: int): list(chess_position) =
        inclusive(pos,i,board,down_option(_,_,_),[])

    diagonal(direction, pos, board): list(chess_position) = 
        rec r(pos: chess_position,i,acc) = match i with
            | 0 -> acc
            | x -> 
                p = match direction with
                    | {left_up}    -> up(pos,board,1) |> Option.bind( p -> left_option(p,board,1),_)
                    | {left_down}  -> down(pos,board,1) |> Option.bind( p-> left_option(p,board,1),_)
                    | {right_up}   -> up(pos,board,1) |> Option.bind( p -> right_option(p,board,1),_) 
                    | {right_down} -> down(pos,board,1) |> Option.bind( p -> right_option(p,board,1),_)
                match p with 
                    | {none} -> acc
                    | {some = p} -> r(p,i-1,[p|acc])
        r(pos,7,[])

    inclusive(pos: chess_position, 
                i: int, 
            board: board, 
                f: chess_position, board, int -> option(chess_position), 
              acc: list(chess_position)
                ): list(chess_position) = match i with
        | 0 -> acc
        | x -> match f(pos,board,1) with
            | {none}  -> acc 
            | ~{some} -> inclusive(some,i-1,board,f,[some|acc])
}}