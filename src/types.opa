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

type direction      = {left_up} / {left_down} / {right_up} / {right_down}


type message = {joining: user} / {state: board}

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

opposite_color = 
    | {white} -> {black}
    | {black} -> {white}

kind_to_string = 
    | {king}   -> "king"
    | {queen}  -> "queen"
    | {rook}   -> "rook"
    | {bishop} -> "bishop"
    | {knight} -> "knight"
    | {pawn}   -> "pawn"
    