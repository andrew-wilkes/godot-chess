extends Control

var selected_piece
var pawn_first_move2 # needed for en passant detection


func _ready():
	$Board.connect("clicked", self, "piece_clicked")
	$Board.connect("unclicked", self, "piece_unclicked")
	$Board.connect("moved", self, "mouse_moved")
	$Board/Grid.connect("mouse_exited", self, "mouse_entered")


# This is called after release of the mouse button and when the mouse
# crosses the Grid border so as to release any selected piece
func mouse_entered():
	return_piece()


func piece_clicked(piece):
	selected_piece = piece
	# Need to ensure that piece displays above all others when moved
	piece.obj.z_index = 1
	print("Board clicked ", selected_piece)


func piece_unclicked(_piece):
	if selected_piece != null:
		var info = $Board.get_position_info(selected_piece)
		print(info.ok)
		# Try to drop the piece
		# Also check for castling and passant
		var ok_to_move = false
		if info.ok:
			if info.piece != null:
				$Board.take_piece(info.piece)
				ok_to_move = true
			else:
				if info.passant and $Board.passant_pawn.pos.x == selected_piece.new_pos.x:
					print("passant")
					$Board.take_piece($Board.passant_pawn)
					ok_to_move = true
				else:
					ok_to_move = selected_piece.key != "P" or selected_piece.pos.x == selected_piece.new_pos.x
				if info.castling:
					# Get rook
					var rook
					var rx
					if selected_piece.new_pos.x == 2:
						rx = 3
						rook = $Board.get_piece_in_grid(0, selected_piece.new_pos.y)
						# Test positions
					else:
						rook = $Board.get_piece_in_grid(7, selected_piece.new_pos.y)
						rx = 5
					if rook != null and rook.key == "R" and rook.tagged:
						# Move rook
						rook.new_pos = Vector2(rx, rook.pos.y)
						$Board.move_piece(rook)
					else:
						ok_to_move = false
		if ok_to_move:
			$Board.move_piece(selected_piece)
		return_piece()

"""
Castling rules
The king and the rook may not have moved from their starting squares if you want to castle.
All spaces between the king and the rook must be empty.
The king cannot be in check.
The squares that the king passes over must not be under attack, nor the square where it lands on
"""

func mouse_moved(pos):
	if selected_piece != null:
		selected_piece.obj.position = pos - Vector2(32, 32)


func return_piece():
	if selected_piece != null:
		# Return the piece to it's start position
		selected_piece.obj.position = Vector2(0, 0)
		selected_piece.obj.z_index = 0
		selected_piece = null
