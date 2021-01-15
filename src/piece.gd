extends Node

class_name Piece

var side : String # The Black or the white "B" or "W"
# The key code used in notation (PRNBQK)
# Pawn Rook kNight Bishop Queen King
var key : String
var obj : Sprite # The sprite object in the running game
var pos = Vector2(0, 0) # position in grid
var moved = false # Used to check if piece has been moved already
