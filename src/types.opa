// 
//  types.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-18.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

type kind           = {king} / {queen} / {rook} / {bishop} / {knight} / {pawn}
type colorC         = {white} / {black}
type piece          = {kind: kind ; color: colorC}
type chess_position = {letter: string ; number: int ; piece: option(piece) }
type board          = {chess_positions: stringmap(intmap(chess_position))}
type direction      = {left_up} / {left_down} / {right_up} / {right_down}

type user = { name: string ; email: string ; password: string }

type User.status = { user: user } / { unlogged }

type message = {joining: user} / {state: board ; turn: colorC}

type game = { white: option(user) ; black: option(user) ; name: string }

type Game.status = { game: string ; color: colorC ; channel: Network.network(message) ; current_color: colorC }

/*
    {Misc functions}
*/

domToList(dom: dom): list(dom) = Dom.fold( dom,acc -> [dom|acc], [], dom) |> List.rev(_)

duplicate(x, xs) = match x with
    | 0 -> xs
    | x -> duplicate(x-1,List.append(xs,xs))

create_string_map(xs: list((string,'a))): stringmap('a) = 
    List.fold( tuple,map -> StringMap_add(tuple.f1,tuple.f2,map),xs,StringMap_empty)

create_int_map(xs: list((int,'a))): intmap('a) = 
    List.fold( tuple,map -> IntMap_add(tuple.f1,tuple.f2,map),xs,IntMap_empty)

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
    