package chess.types

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

type Game.status = { game: string ; color: colorC ; channel: Network.network(message)}