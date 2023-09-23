extends Node

class_name Piece

var side : String # The Black or the white "B" or "W"
# The key code used in notation (PRNBQK)
# Pawn Rook kNight Bishop Queen King
var key : String
var obj : Sprite2D # The sprite object in the running game
var pos = Vector2(0, 0) # position in grid
var new_pos = Vector2(0, 0) # position to move to in grid coors
var tagged = false # Used to indicate if castling is enabled for Rook or King
