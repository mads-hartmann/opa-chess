// 
//  column.opa
//  chess
//  
//  Created by Mads Hartmann Jensen on 2011-08-18.
//  Copyright 2011 Sideways Coding. All rights reserved.
// 

package chess

Column = {{
    
    to_int(x: string): int = String.byte_at_unsafe(0, x)
    
    from_int(x: int): string = Text.to_string(Text.from_character(x))
    
    next(letter: string): string = 
        Column.to_int(letter) |> x -> Column.from_int(x+1)
    
}}