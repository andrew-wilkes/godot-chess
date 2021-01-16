extends Control

signal clicked
signal unclicked
signal moved

export var square_width = 64 # pixels (same as chess piece images)
export(Color) var white # Square color
export(Color) var grey # Square color
export(Color) var mod_color # For highlighting squares

const num_squares = 64

var grid : Array # Map of what pieces are placed on the board

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_tiles()
	setup_pieces() # Starting positions
	#test_square_is_white()
	#test_highlight_square()


func setup_pieces():
	var seq = "PPPPPPPPRNBQKBNRPPPPPPPP" # Arrangement order for chess pieces
	for i in 16:
		# Place black pieces
		var bp = Piece.new()
		bp.side = "B"
		bp.key = seq[i + 8]
		bp.obj = Pieces.get_piece(bp.key, "B")
		bp.pos = Vector2(i % 8, i / 8)
		grid[i] = bp
		$Grid.get_child(i).add_child(bp.obj)
		# Place white pieces
		var wp = Piece.new()
		wp.side = "W"
		wp.key = seq[i]
		wp.obj = Pieces.get_piece(wp.key)
		wp.pos = Vector2(i % 8, 6 + i / 8)
		grid[i + 48] = wp
		$Grid.get_child(i + 48).add_child(wp.obj)


func draw_tiles():
	var white_square = ColorRect.new()
	white_square.color = white
	white_square.mouse_filter = Control.MOUSE_FILTER_PASS
	white_square.rect_min_size = Vector2(square_width, square_width)
	var grey_square = white_square.duplicate()
	grey_square.color = grey
	# Add squares to grid
	var odd = true
	for y in 8:
		odd = !odd
		for x in 8:
			odd = !odd
			if odd:
				add_square(white_square.duplicate(), x, y)
			else:
				add_square(grey_square.duplicate(), x, y)


func add_square(s: ColorRect, x: int, y: int):
	s.connect("gui_input", self, "square_event", [x, y])
	$Grid.add_child(s)


func square_event(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()
		print("Clicked at: ", [x, y])
		var p = get_piece_in_grid(x, y)
		print(p)
		if event.pressed:
			if p != null:
				emit_signal("clicked", p)
		else:
			emit_signal("unclicked", p)
	# Mouse position is relative to the square
	if event is InputEventMouseMotion:
		emit_signal("moved", event.position)


func get_piece_in_grid(x: int, y: int):
	var p = grid[x + 8 * y]
	return p


func move_piece(p: Piece):
	grid[p.pos.x + 8 * p.pos.y] = null
	grid[p.new_pos.x + 8 * p.new_pos.y] = p
	p.pos = p.new_pos
	# Re-parent piece on board
	p.obj.get_parent().remove_child(p.obj)
	$Grid.get_child(p.pos.x + 8 * p.pos.y).add_child(p.obj)


func test_highlight_square():
	for n in num_squares:
		highlight_square(n)
		yield(get_tree().create_timer(0.1), "timeout")
		highlight_square(n, false)


func highlight_square(n: int, apply = true):
	assert(n >= 0)
	assert(n < num_squares)
	var sqr: ColorRect = $Grid.get_child(n)
	if apply:
		sqr.color = mod_color
	else:
		if square_is_white(n):
			sqr.color = white
		else:
			sqr.color = grey


func test_square_is_white():
	for n in num_squares:
		if $Grid.get_child(n).color == white:
			assert(square_is_white(n))
		else:
			assert(!square_is_white(n))


func square_is_white(n: int):
# warning-ignore:integer_division
	return 0 == ((n / 8) + n) % 2


# Check if it is valid to move to this position
# Return true/false and null/piece that occupies the position and castling flag
func get_position_info(p: Piece, offset_divisor = square_width):
	var castling = false
	var offset = p.obj.position / offset_divisor
	var x = int(round(offset.x))
	var y = int(round(offset.y))
	p.new_pos = Vector2(p.pos.x + x, p.pos.y + y)
	var ax = int(abs(x))
	var ay = int(abs(y))
	var p2 = get_piece_in_grid(p.new_pos.x, p.new_pos.y)
	# Check for valid move
	# Don't care about bounds of the board since the piece will be released if outside
	var ok = false
	var check_path = true
	match p.key:
		"P": # Check for valid move of pawn
			if p.side == "B":
				ok = y > 0 and (y == 1 or !p.moved and y == 2)
			else:
				ok = y < 0 and (y == -1 or !p.moved and -2 == y)
			# Check for valid horizontal move
			if ok:
				ok = ax == 0 or ay == 1 and ax == 1
		"R": # Check for valid horizontal or vertical move of rook
			ok = ax > 0 and ay == 0 or ax == 0 and ay > 0
		"B": # Check for valid diagonal move of bishop
			ok = ax == ay
		"K": # Check for valid move of king
			ok = ax < 2 and ay < 2
			if ax == 2 and not p.moved:
				castling = true # Potential castling situation
				ok = true
		"N": # Check for valid move of knight
			check_path = false # knight may jump over pieces
			ok = ax == 2 and ay == 1 or ax == 1 and ay == 2
	# Check for landing on own piece
	if ok and p2 != null:
		ok = (p.side == "B" and p2.side == "W") or (p.side == "W" and p2.side == "B")
	# Check for passing over a piece
	if check_path and ok and (ax > 1 or ay > 1):
		var checking = true
		while checking:
			if ax > 0:
				x -= sign(x) # Move back horizontally
			if ay > 0:
				y -= sign(y) # Move back vertically
			var p3 = get_piece_in_grid(p.pos.x + x, p.pos.y + y)
			ok = p3 == null
			ax -= 1
			ay -= 1
			checking = (ax > 1 or ay > 1) and ok
	return { "ok": ok, "piece": p2, "castling": castling }
