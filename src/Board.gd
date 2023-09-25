extends Control

class_name Board

signal clicked
signal unclicked
signal moved
signal halfmove
signal fullmove
signal taken

@export var square_width = 64 # pixels (same as chess piece images)
@export var white: Color # Square color
@export var grey: Color # Square color
@export var mod_color: Color # For highlighting squares

const num_squares = 64
enum { SIDE, UNDER }

var grid : Array # Map of what pieces are placed on the board
var r_count = 0 # Rook counter
var R_count = 0 # Rook counter
var halfmoves = 0 # Used with fifty-move rule. Reset after pawn move or piece capture
var fullmoves = 0 # Incremented after Black's move
var passant_pawn : Piece
var kings = {}
var fen = ""
var default_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0"
var cleared = true
var highlighed_tiles = []

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_tiles()
	#hide_labels()
	# Set board layout using Forsyth Edwards encoded string
	#setup_pieces("r1b1k2r/5pp1/p3p2p/2b4P/2BnnKP1/1P41q/P1PP4/1RBQ4 w qk - 43 21")
	setup_pieces()
	#test_square_is_white()
	#test_highlight_square()
	#print(position_to_move(Vector2(0, 0)))
	#print(move_to_position("h1"))
	#highlighed_tiles = [0,2,4,6,8]
	#$HighlightTimer.start()
	#highlight_square(highlighed_tiles[0])
	#test_pgn_to_long_conversion()

#func _gui_input(event):
#	print("Main receive Event : ", event)

func test_pgn_to_long_conversion():
	print(pgn_to_long("a4", "W"))
	print(pgn_to_long("h3", "W"))
	print(pgn_to_long("axb3", "W"))
	print(pgn_to_long("Nbc3", "W"))
	print(pgn_to_long("Nbxc3", "W"))
	print(pgn_to_long("Nf3", "W"))
	print(pgn_to_long("Nxf3", "W"))
	print(pgn_to_long("N1xc3", "W"))
	print(pgn_to_long("N1c3", "W"))
	print(pgn_to_long("O-O", "W"))
	print(pgn_to_long("O-O-O", "W"))
	print(pgn_to_long("O-O", "B"))
	print(pgn_to_long("O-O-O", "B"))
	print(pgn_to_long("a5", "B"))
	print(pgn_to_long("h6", "B"))
	print(pgn_to_long("axb6", "B"))
	print(pgn_to_long("Nbc6", "B"))
	print(pgn_to_long("Nbxc6", "B"))
	print(pgn_to_long("Nf6", "B"))
	print(pgn_to_long("Nxf6", "B"))
	print(pgn_to_long("N8xc6", "B"))
	print(pgn_to_long("N8c6", "B"))


# convert grid position to move code e.g. 0,0 -> a8
func position_to_move(pos: Vector2) -> String:
	assert(pos.x >= 0)
	assert(pos.y >= 0)
	assert(pos.x < 8)
	assert(pos.y < 8)
	return "%s%d" % [char(97 + int(pos.x)), 8 - int(pos.y)]


# convert move code to grid position e.g. h1 -> 7,7
func move_to_position(move: String) -> Vector2:
	assert(move.length() == 2)
	var pos = Vector2(move.unicode_at(0) - 97, 8 - int(move[1]))
	assert(pos.x >= 0)
	assert(pos.y >= 0)
	assert(pos.x < 8)
	assert(pos.y < 8)
	return pos


# The following code requires that the piece layout is in sync with the moves
# If the user moves a piece, then the pgn move list should be wiped
# The idea is to play back the moves of a game and take over at any point
func pgn_to_long(pgn: String, side: String):
	print(pgn, " ", side)
	var m = ""
	var ch = pgn[0]
	# Pawn moves ignoring =Q in dxc1=Q
	if ch.unicode_at(0) > 96: # a .. h
		var y
		if pgn[1] == "x":
			m = pgn.substr(0, 4) #exf6 e?f6
			y = int(pgn[3])
		else:
			m = pgn.substr(0, 2) #f4
			m += m # fff4 f?f4
			y = int(pgn[1])
		m[1] = String(8 - find_pawn_in_col(ch, y, side))
		return m
	# Castling
	if pgn.begins_with("O-O-O"):
		if side == "B":
			return "e8b8"
		else:
			return "e1b1"
	if pgn.begins_with("O-O"):
		if side == "B":
			return "e8g8"
		else:
			return "e1g1"
	pgn = pgn.replace("x", "").substr(1).rstrip("+")
	if pgn.length() > 2: #Nef6 e?f6
		if pgn[0].is_valid_int(): # B1d4 ?1d4
			m = char(97 + find_piece_in_row(pgn[0], ch, side)) + pgn
		else:
			m = pgn[0] + String(8 - find_piece_in_col(pgn[0], ch, side)) + pgn.substr(1)
	else:
		# Here we have the least amount of move information e.g. #Nf6
		m = find_piece_in_grid(ch, side, move_to_position(pgn)) + pgn
	return m


func find_piece_in_row(n, key, side):
	var y = 8 - int(n)
	for x in 8:
		var i = get_grid_index(x, y)
		if grid[i] != null and grid[i].key == key and grid[i].side == side:
			return x
	return -1


func find_piece_in_col(ch, key, side):
	var x = ch.unicode_at(0) - 97
	for y in 8:
		var i = get_grid_index(x, y)
		if grid[i] != null and grid[i].key == key and grid[i].side == side:
			return y
	return -1


func find_piece_in_grid(key, side, pos: Vector2):
	for i in 64:
		var p = grid[i]
		if p != null and p.key == key and p.side == side:
			# See if piece can move to destination
			p.new_pos = pos
			if get_position_info(p, true, true).ok:
				return position_to_move(p.pos)


# Return -1 on error
func find_pawn_in_col(ch, y, side):
	var x = ch.unicode_at(0) - 97
	var dy = 1 if side == "W" else -1
	y = 8 - y + dy
	var i = get_grid_index(x, y)
	if grid[i] != null:
		return y if grid[i].key == "P" else -1
	else: 
		y += dy
		i = get_grid_index(x, y)
		if grid[i] != null:
			return y if grid[i].key == "P" else -1
	return -1


func setup_pieces(_fen = default_fen):
	var parts = _fen.split(" ")
	var next_move_white = parts.size() < 2 or parts[1] == "w"
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
	# Tag pawn for en passant
	if parts.size() >= 4 and parts[3].length() == 2:
		i = parts[3][0].to_ascii_buffer()[0] - 96 # ASCII 'a' = 97
		if i >= 0 and i < 8:
			# Only valid rank is 3 or 6
			match parts[3][1]:
				"3":
					tag_piece(i + 32)
				"6":
					tag_piece(i + 24)
	# Set halfmoves value
	if parts.size() >= 5 and parts[4].is_valid_int():
		set_halfmoves(parts[4].to_int())
	# Set fullmoves value
	if parts.size() >= 6 and parts[5].is_valid_int():
		set_fullmoves(parts[5].to_int())
	return next_move_white


func get_fen(next_move):
	var gi = 0 # Grid index
	var ns = 0 # Number of blank horizontal tile places counter
	var castling = ""
	var _fen = ""
	for y in 8:
		for x in 8:
			var p = grid[gi]
			gi += 1
			if p == null:
				ns += 1
			else:
				if ns > 0:
					_fen += str(ns)
					ns = 0
				var key = p.key
				if p.side == "B":
					key = key.to_lower()
				_fen += key
		if ns > 0:
			_fen += str(ns)
			ns = 0
		if y < 7:
			_fen += "/"
	if is_tagged(0) and is_tagged(4):
		castling += "q"
	if is_tagged(4) and is_tagged(7):
		castling += "k"
	if is_tagged(56) and is_tagged(60):
		castling += "Q"
	if is_tagged(60) and is_tagged(63):
		castling += "K"
	var pas = "-"
	var pos
	if passant_pawn != null:
		pos = passant_pawn.pos
		if passant_pawn.side == "B":
			pos.y -= 1
		else:
			pos.y += 1
		pas = position_to_move(pos)
	_fen += " %s %s %s %d %d" % [next_move, castling, pas, halfmoves, fullmoves]
	return _fen


func is_tagged(i):
	return grid[i] != null and grid[i].tagged


func tag_piece(i: int):
	if grid[i] != null:
		grid[i].tagged = true


func set_piece(key: String, i: int, castling: String):
	var p = Piece.new()
	p.key = key.to_upper()
	p.side = "W" if "a" > key else "B"
	@warning_ignore("integer_division")
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
			kings[p.side] = p
		"R":
			R_count += 1
			if R_count == 1:
				p.tagged = "Q" in castling
			else:
				p.tagged = "K" in castling
		"K":
			p.tagged = "K" in castling or "Q" in castling
			kings[p.side] = p


func clear_board():
	for i in 64:
		take_piece(grid[i], false)
	cleared = true


func take_piece(p: Piece, emit = true):
	if p == null:
		return
	p.obj.get_parent().remove_child(p.obj)
	grid[get_grid_index(p.pos.x, p.pos.y)] = null
	set_halfmoves(0)
	if emit:
		emit_signal("taken", p)


func set_halfmoves(n):
	halfmoves = n
	emit_signal("halfmove", n)


func set_fullmoves(n):
	fullmoves = n
	emit_signal("fullmove", n)


func draw_tiles():
	var white_square = ColorRect.new()
	white_square.color = white
	white_square.mouse_filter = Control.MOUSE_FILTER_STOP
	white_square.custom_minimum_size = Vector2(square_width, square_width)
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
	s.connect("gui_input", Callable(self, "square_event").bind(x, y))
	if x == 0:
		add_label(s, SIDE, str(8 - y))
	if y == 7:
		add_label(s, UNDER, char(97 + x))
	$Grid.add_child(s)


func add_label(node, pos, chr):
	var l = Label.new()
	l.add_to_group("labels")
	l.text = chr
	if pos == SIDE:
		l.position = Vector2(-square_width / 4.0, square_width / 2.3)
	else:
		l.position = Vector2(square_width / 2.3, square_width * 1.1)
	node.add_child(l)


func hide_labels(show_labels = false):
	for label in get_tree().get_nodes_in_group("labels"):
		label.visible = show_labels


func square_event(event: InputEvent, x: int, y: int):
	#print("event type : ", event.get_class())
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		print("Clicked at: ", [x, y])
		var p = get_piece_in_grid(x, y)
		print(p)
		if p != null:
			if event.pressed:
				emit_signal("clicked", p)
			else:
				print("unclick event : ", p)
				emit_signal("unclicked", p)
	# Mouse position is relative to the square
	if event is InputEventMouseMotion:
		emit_signal("moved", event.position)


func get_grid_index(x: int, y: int):
	return x + 8 * y


func get_piece_in_grid(x: int, y: int):
	var p = grid[get_grid_index(x, y)]
	return p


func move_piece(p: Piece, engine_turn: bool):
	var pos = get_grid_index(p.pos.x, p.pos.y)
	if engine_turn:
		highlighed_tiles.append(pos)
	grid[pos] = null
	pos = get_grid_index(p.new_pos.x, p.new_pos.y)
	if engine_turn:
		highlighed_tiles.append(pos)
	grid[pos] = p
	p.pos = p.new_pos
	# Re-parent piece on board
	p.obj.get_parent().remove_child(p.obj)
	p.obj.position = Vector2(0, 0)
	$Grid.get_child(p.pos.x + 8 * p.pos.y).add_child(p.obj)
	if p != passant_pawn:
		passant_pawn = null
	p.tagged = false # Prevent castling after move
	if p.key == "P":
		set_halfmoves(0)
	else:
		set_halfmoves(halfmoves + 1)
	if p.side == "B":
		set_fullmoves(fullmoves + 1)
	if engine_turn:
		$HighlightTimer.start()
		highlight_square(highlighed_tiles[0])
	else:
		highlighed_tiles = []
	cleared = false


func is_king_checked(p: Piece):
	# We flip the side to be checked here depending on if the piece is a king or not
	var side = p.side
	if p.key == "K":
		return { "checked": is_checked(p.new_pos.x, p.new_pos.y, side) }
	else:
		if p.side == "B":
			side = "W"
		else:
			side = "B"
		var pos = Vector2(kings[side].pos.x, kings[side].pos.y)
		var mated = false
		var checked = is_checked(pos.x, pos.y, side)
		if checked:
			# Scan for check mate
			var offsets = [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]]
			mated = true
			for o in offsets:
				if king_can_move_to(pos.x + o[0], pos.y + o[1], side):
					mated = is_checked(pos.x + o[0], pos.y + o[1], side)
				if !mated:
					break
		return { "checked": checked, "mated": mated, "side": side }


func king_can_move_to(x, y, side):
	if x < 0 or x > 7 or y < 0 or y > 7:
		return false
	var p = get_piece_in_grid(x, y)
	return p == null or p.side != side


# Check if position is under attack
func is_checked(x, y, side):
	# pawns
	var key1 = "P"
	var key2 = ""
	var can = false
	if side == "B":
		can = can_attack(x - 1, y + 1, side, key1) or can_attack(x + 1, y + 1, side, key1)
	else:
		can = can_attack(x - 1, y - 1, side, key1) or can_attack(x + 1, y - 1, side, key1)
	if can:
		return can
	
	# king
	key1 = "K"
	if can_attack(x - 1, y + 1, side, key1) or can_attack(x + 1, y + 1, side, key1) or can_attack(x - 1, y - 1, side, key1) or can_attack(x + 1, y - 1, side, key1):
		return true
	
	# rooks and queen
	key1 = "R"
	key2 = "Q"
	if scan_for_attacking_piece(x, y, 1, 0, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, -1, 0, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, 0, -1, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, 0, 1, side, key1, key2):
		return true
	
	# bishops and queen
	key1 = "B"
	if scan_for_attacking_piece(x, y, -1, -1, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, 1, -1, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, -1, 1, side, key1, key2):
		return true
	if scan_for_attacking_piece(x, y, 1, 1, side, key1, key2):
		return true
	
	# Knight
	key1 = "N"
	if can_attack(x - 1, y + 2, side, key1) or can_attack(x + 1, y + 2, side, key1) or can_attack(x - 1, y - 2, side, key1) or can_attack(x + 1, y - 2, side, key1) or can_attack(x - 2, y - 1, side, key1) or can_attack(x - 2, y + 1, side, key1) or can_attack(x + 2, y - 1, side, key1) or can_attack(x + 2, y + 1, side, key1):
		return true
	return false


func scan_for_attacking_piece(ox, oy, incx, incy, side, key1, key2 = ""):
	var can = false
	var j = ox
	var k = oy
	var p = null
	while(p == null):
		j += incx
		k += incy
		if j < 0 or j > 7 or k < 0 or k > 7:
			break
		p = get_piece_in_grid(j, k)
		can = p != null and p.side != side and (p.key == key1 or p.key == key2)
	return can


func can_attack(x, y, side, key):
	if x < 0 or x > 7 or y < 0 or y > 7:
		return false
	var p = get_piece_in_grid(x, y)
	return p != null and p.side != side and p.key == key


func test_highlight_square():
	for n in num_squares:
		highlight_square(n)
		await get_tree().create_timer(0.1).timeout
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
	@warning_ignore("integer_division")
	return 0 == ((n / 8) + n) % 2


# Check if it is valid to move to the new position of a piece
# Return true/false and null/piece that occupies the position plus
# castling and passant flags to indicate to check for these situations
func get_position_info(p: Piece, non_player_move, offset_divisor = square_width):
	var castling = false
	var passant = false
	var x: int
	var y: int
	if non_player_move:
		x = int(p.new_pos.x - p.pos.x)
		y = int(p.new_pos.y - p.pos.y)
	else:
		# p.new_pos needs to be set based on position of manually moved piece
		var offset = p.obj.position / offset_divisor
		x = int(round(offset.x))
		y = int(round(offset.y))
		p.new_pos = Vector2(p.pos.x + x, p.pos.y + y)
	if p.new_pos.x < 0 or p.new_pos.y < 0 or p.new_pos.x > 7 or p.new_pos.y > 7:
		# piece dropped outside of grid
		return { "ok": false }
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
				passant = y == 1 and ax == 1 and p.pos.y == 4
			else:
				ok = y == -1
				if p.pos.y == 6 and -2 == y:
					ok = true
					passant_pawn = p
				passant = y == -1 and ax == 1 and p.pos.y == 3
			# Check for valid horizontal move
			if ok:
				ok = ax == 0 and p2 == null or ay == 1 and ax == 1
		"R": # Check for valid horizontal or vertical move of rook
			ok = ax > 0 and ay == 0 or ax == 0 and ay > 0
		"B": # Check for valid diagonal move of bishop
			ok = ax == ay
		"K": # Check for valid move of king
			ok = ax < 2 and ay < 2
			if ax == 2 and ay == 0 and p2 == null and p.tagged: # Moved 2 steps in x and tagged
				if p.side == "B" and p.pos.x == 4 and p.pos.y == 0 or p.side == "W" and p.pos.x == 4 and p.pos.y == 7:
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
				x -= int(sign(x)) # Move back horizontally
			if ay > 0:
				y -= int(sign(y)) # Move back vertically
			var p3 = get_piece_in_grid(p.pos.x + x, p.pos.y + y)
			ok = p3 == null
			ax -= 1
			ay -= 1
			checking = (ax > 1 or ay > 1) and ok
	if !ok and p == passant_pawn:
		passant_pawn = null
	return { "ok": ok, "piece": p2, "castling": castling, "passant": passant }


func _on_HighlightTimer_timeout():
	var tile = highlighed_tiles.pop_front()
	if tile != null:
		highlight_square(tile, false)
	if highlighed_tiles.size() > 0:
		highlight_square(highlighed_tiles[0])
		$HighlightTimer.start()
