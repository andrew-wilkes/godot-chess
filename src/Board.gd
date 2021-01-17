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
var r_count = 0 # Rook counter
var R_count = 0 # Rook counter
var active_color = ""
var halfmoves = 0 # Used with fifty-move rule. Reset after pawn move or capture
var fullmoves = 0 # Incremented after Black's move
var passant_pawn

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_tiles()
	# Input board layout
	# https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
	setup_pieces("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	#test_square_is_white()
	#test_highlight_square()


func setup_pieces(fen: String):
	var parts = fen.split(" ")
	active_color = "W" if parts.size() < 2 else parts[1].to_upper()
	var castling = "" if parts.size() < 3 else parts[2]
	r_count = 0
	R_count = 0
	var i = 0
	for ch in parts[0]:
		match ch:
			"/": # Next rank
				pass
			"1", "2", "3", "4", "5", "6", "7", "8":
				i += int(ch)
			_:
				set_piece(ch, i, castling)
				i += 1 
	# Tag pawn for en passent
	if parts.size() >= 4 and parts[3].length() == 2:
		i = parts[3][0].to_ascii()[0] - 96 # ASCII 'a' = 97
		if i >= 0 and i < 8:
			# Only valid rank is 3 or 6
			match parts[3][1]:
				"3":
					tag_piece(i + 32)
				"6":
					tag_piece(i + 24)
	# Set halfmoves value
	if parts.size() >= 5 and parts[4].is_valid_integer():
		halfmoves = parts[4].to_int()
	# Set fullmoves value
	if parts.size() >= 6 and parts[5].is_valid_integer():
		fullmoves = parts[5].to_int()


func tag_piece(i: int):
	if grid[i] != null:
		grid[i].tagged = true


func set_piece(key: String, i: int, castling: String):
	var p = Piece.new()
	p.key = key.to_upper()
	p.side = "W" if "a" > key else "B"
# warning-ignore:integer_division
	p.pos = Vector2(i % 8, i / 8)
	p.obj = Pieces.get_piece(p.key, p.side)
	grid[i] = p
	$Grid.get_child(i).add_child(p.obj)
	# Check castling rights
	match key:
		"r":
			r_count += 1
			if r_count == 1:
				p.tagged = "q" in castling
			else:
				p.tagged = "k" in castling
		"k":
			p.tagged = "k" in castling or "q" in castling
		"R":
			R_count += 1
			if R_count == 1:
				p.tagged = "Q" in castling
			else:
				p.tagged = "K" in castling
		"K":
			p.tagged = "K" in castling or "Q" in castling


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
	if p != passant_pawn:
		passant_pawn = null


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


# Check if it is valid to move to the new position of a piece
# Return true/false and null/piece that occupies the position plus
# castling and passant flags to indicate to check for these situations
func get_position_info(p: Piece, offset_divisor = square_width):
	var castling = false
	var passant = false
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
				ok = y == 1
				if p.pos.y == 1 and y == 2:
					ok = true
					passant_pawn = p
				if y == 1 and ax == 1 and p.pos.y == 3:
					passant = true
					if p2 == null:
						p2 = passant_pawn
			else:
				ok = y == -1
				if p.pos.y == 6 and -2 == y:
					ok = true
					passant_pawn = p
				if y == -1 and ax == 1 and p.pos.y == 4:
					passant = true
					if p2 == null:
						p2 = passant_pawn
			# Check for valid horizontal move
			if ok:
				ok = ax == 0 or ay == 1 and ax == 1
		"R": # Check for valid horizontal or vertical move of rook
			ok = ax > 0 and ay == 0 or ax == 0 and ay > 0
		"B": # Check for valid diagonal move of bishop
			ok = ax == ay
		"K": # Check for valid move of king
			ok = ax < 2 and ay < 2
			if ax == 2 and p.tagged: # Moved 2 steps in x and tagged
				castling = true # Potential castling situation
				ok = true
		"N": # Check for valid move of knight
			check_path = false # knight may jump over pieces
			ok = ax == 2 and ay == 1 or ax == 1 and ay == 2
		"Q": # Add the queen to the checking process of hopping over pieces
			ok = true
	# Check for landing on own piece
	if ok and p2 != null:
		ok = p.side == "B" and p2.side == "W" or p.side == "W" and p2.side == "B"
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
	if !ok and p == passant_pawn:
		passant_pawn = null
	return { "ok": ok, "piece": p2, "castling": castling, "passant": passant }
