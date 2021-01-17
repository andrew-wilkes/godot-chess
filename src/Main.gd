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
		# Take piece
		# If info.piece == passant_pawn and info.passant
		if info.ok:
			if info.piece == null:
				$Board.move_piece(selected_piece)
		return_piece()


func mouse_moved(pos):
	if selected_piece != null:
		selected_piece.obj.position = pos - Vector2(32, 32)


func return_piece():
	if selected_piece != null:
		# Return the piece to it's start position
		selected_piece.obj.position = Vector2(0, 0)
		selected_piece.obj.z_index = 0
		selected_piece = null
