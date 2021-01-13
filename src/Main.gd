extends Control

var selected_piece

func _ready():
	$Board.connect("clicked", self, "piece_clicked")
	$Board.connect("unclicked", self, "piece_unclicked")
	$Board.connect("moved", self, "mouse_moved")
	$Board/Grid.connect("mouse_exited", self, "mouse_entered")


# This is called after release of the mouse button and when the mouse
# crosses the Grid border so as to release any selected piece
func mouse_entered():
	return_piece()


func piece_clicked(x, y, side, code, piece):
	selected_piece = {
		"position": Vector2(x, y),
		"side": side,
		"code": code,
		"piece": piece
	}
	# Need to ensure that piece displays above all others when moved
	piece.z_index = 1
	print("Board clicked ", selected_piece)


func piece_unclicked(_x, _y, _side, _code, _piece):
	if selected_piece != null:
		# Try to drop the piece
		return_piece()


func mouse_moved(pos):
	if selected_piece != null:
		selected_piece.piece.position = pos - Vector2(32, 32)


func return_piece():
	if selected_piece != null:
		# Return the piece to it's start position
		selected_piece.piece.position = Vector2(0, 0)
		selected_piece.piece.z_index = 0
		selected_piece = null
