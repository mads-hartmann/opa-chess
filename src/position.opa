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
        // short-cuts. No need to explicitly pass the board all over the code. 
        r     = right(_,1)
        l     = left(_,1)
        u     = up(_,1)
        d     = down(_,1)
        rOpt  = right_option(_,board,_)
        lOpt  = left_option(_,board,_)
        uOpt  = up_option(_,board,_)
        dOpt  = down_option(_,board,_)
        dig   = diagonal(_,pos,board)
        rIncl = right_inclusive(pos,board,_)
        lIncl = left_inclusive(pos,board,_)
        uIncl = up_inclusive(pos,board,_)
        dIncl = down_inclusive(pos,board,_)
        
        has_enemy(pos) = Board.has_piece_of_opposite_color(board,pos.number,pos.letter)
        cant_kill(pos) = if has_enemy(pos) then {none} else {some = pos}
        
        // would've named then 'andThen' but you can't have chars in infix functions. 
        `<*>` = p,q -> Option.bind( x -> q(x),p)
        
        king_movements = 
            [rOpt(pos,1), 
             lOpt(pos,1), 
             uOpt(pos,1), 
             dOpt(pos,1), 
             r(pos) <*> uOpt(_,1), 
             r(pos) <*> dOpt(_,1), 
             l(pos) <*> uOpt(_,1), 
             l(pos) <*> dOpt(_,1)]
        
        knight_movements = 
            [r(pos) <*> dOpt(_,2), 
             r(pos) <*> uOpt(_,2), 
             l(pos) <*> dOpt(_,2), 
             l(pos) <*> uOpt(_,2), 
             u(pos) <*> lOpt(_,2), 
             u(pos) <*> rOpt(_,2), 
             d(pos) <*> lOpt(_,2), 
             d(pos) <*> rOpt(_,2)]

        bishop_movements = 
            List.flatten(
                [dig({left_up}),
                 dig({left_down}),
                 dig({right_up}),
                 dig({right_down})
                ]) |> List.map( x -> { some = x}, _)
        
        queen_movements =
            (dig({left_up})
             ++ dig({left_down})
             ++ dig({right_up})
             ++ dig({right_down})
             ++ lIncl(7)
             ++ rIncl(7)
             ++ uIncl(7)
             ++ dIncl(7)) |> List.map( x -> { some = x}, _)

        rook_movements = 
            List.flatten(
                [rIncl(7), 
                 lIncl(7), 
                 uIncl(7), 
                 dIncl(7)
                ]) |> List.map( x -> { some = x}, _)
        
        pawn_movements = 
        (
            f(g: chess_position -> option(chess_position), xs: list(chess_position)): list(option(chess_position)) = 
                List.filter_map(g, xs) |> List.map( x -> {some = x}, _)
            
            mov(special, movment_func_incl,movement_func) = 
            (
                possible_movements = 
                    if pos.number == special
                    then movment_func_incl(2) |> List.filter_map(cant_kill(_),_)
                    else List.filter_map(x -> x, [movement_func(pos)]) |> List.filter_map(cant_kill(_),_)

                possible_attacks = (
                    xs = [ movement_func(pos) <*> r, movement_func(pos) <*> l ]
                    List.filter_map(x -> x,xs))
                    
                movements = f(x -> if has_enemy(x) then {none} else {some = x}, possible_movements)
                attacks   = f(x -> if has_enemy(x) then {some = x} else {none}, possible_attacks)

                movements ++ attacks
            )
            
            if user_color == {white} then mov(2,uIncl,u) else mov(7,dIncl,d)
        )
        
        (match piece.kind with
            | {king}   -> king_movements
            | {knight} -> knight_movements
            | {bishop} -> bishop_movements
            | {queen}  -> queen_movements
            | {rook}   -> rook_movements
            | {pawn}   -> pawn_movements) |> List.filter_map( x -> x , _)
    )

    /*
        Helper functions. 
    */

    mov_opt(pos,board,i,f) =
        match f(pos,i) with
            | {none} -> {none}
            | ~{some} -> if Board.has_piece_of_own_color(board,some.number,some.letter) then {none} else {some = some}

    right_option(pos,board,i) = mov_opt(pos,board,i,right(_,_))
    left_option(pos,board,i)  = mov_opt(pos,board,i,left(_,_))
    up_option(pos,board,i)    = mov_opt(pos,board,i,up(_,_))
    down_option(pos,board,i)  = mov_opt(pos,board,i,down(_,_))
        
    right(pos: chess_position, i: int): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x+i)
        next_pos = {pos with letter = l}
        if (x+i) > 72 then {none} else {some = next_pos}
    
    left(pos: chess_position, i: int): option(chess_position) = 
        x = Column.to_int(pos.letter)
        l = Column.from_int(x-i)
        next_pos = {pos with letter = l}
        if (x-i) < 65 then {none} else {some = next_pos}
            
    up(pos: chess_position, i: int): option(chess_position) = 
        next_pos = {pos with number = pos.number+i}
        if (pos.number + i) > 8 then {none} else {some = next_pos}
                                                     
    down(pos: chess_position, i: int): option(chess_position) = 
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
            | _ -> 
                p = match direction with
                    | {left_up}    -> up(pos,1) |> Option.bind( p -> left_option(p,board,1),_)
                    | {left_down}  -> down(pos,1) |> Option.bind( p-> left_option(p,board,1),_)
                    | {right_up}   -> up(pos,1) |> Option.bind( p -> right_option(p,board,1),_) 
                    | {right_down} -> down(pos,1) |> Option.bind( p -> right_option(p,board,1),_)
                match p with 
                    | {none} -> acc
                    | {some = p} -> if Board.has_piece_of_opposite_color(board, p.number, p.letter) 
                                    then [p|acc]
                                    else r(p,i-1,[p|acc])
        r(pos,7,[])

    inclusive(pos: chess_position, 
                i: int, 
            board: board, 
                f: chess_position, board, int -> option(chess_position), 
              acc: list(chess_position)
                ): list(chess_position) = match i with
        | 0 -> acc
        | _ -> match f(pos,board,1) with
            | {none}  -> acc 
            | ~{some} -> if Board.has_piece_of_opposite_color(board, some.number, some.letter) 
                         then [some|acc] 
                         else inclusive(some,i-1,board,f,[some|acc])
}}