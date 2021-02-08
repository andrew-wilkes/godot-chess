extends Control

var selected_piece
var board
var engine
var pid = 0
var moves: PoolStringArray
var fen = "test"
var show_suggested_move = true
var white_next = true
var fd: FileDialog

enum { IDLE, CONNECTING, STARTING, PLAYER_TURN, ENGINE_TURN, PLAYER_WIN, ENGINE_WIN } # states
var state = IDLE
enum { CONNECT, NEW_GAME, DONE, ERROR, MOVE } # events

func _ready():
	board = find_node("Board")
	board.connect("clicked", self, "piece_clicked")
	board.connect("unclicked", self, "piece_unclicked")
	board.connect("moved", self, "mouse_moved")
	board.get_node("Grid").connect("mouse_exited", self, "mouse_entered")
	board.connect("taken", self, "stow_taken_piece")
	engine = $Engine
	ponder()
	var c = ColorRect.new()
	c.color = Color.green
	c.rect_min_size = Vector2(64, 64)
	fd = $c/FileDialog
	#fen_from_file("0000D,5rk1/1p3ppp/pq3b2/8/8/1P1Q1N2/P4PPP/3R2K1 w - - 2 27,d3d6 f8d8 d6d8 f6d8,1426,500,2,0,advantage endgame short,https://lichess.org/F8M8OS71#53")
	#fen_from_file("r2qr1k1/b1p2ppp/pp4n1/P1P1p3/4P1n1/B2P2Pb/3NBP1P/RN1QR1K1 b - - 1 16")


func handle_state(event, msg = ""):
	match state:
		IDLE:
			match event:
				CONNECT:
					var status = engine.start_udp_server()
					if status.started:
						# Need some delay before connecting is possible
						yield(get_tree().create_timer(0.5), "timeout")
						engine.send_packet("uci")
						state = CONNECTING
					else:
						alert(status.error)
				NEW_GAME:
					reset_board()
					if engine.server_pid > 0:
						engine.send_packet("ucinewgame")
						engine.send_packet("isready")
						state = STARTING
					else:
						handle_state(CONNECT)
		CONNECTING:
			match event:
				DONE:
					if msg == "uciok":
						state = IDLE
						handle_state(NEW_GAME)
				ERROR:
					alert("Unable to connect to Chess Engine!")
					state = IDLE
		STARTING:
			match event:
				DONE:
					if msg == "readyok":
						if white_next:
							alert("White to begin")
							state = PLAYER_TURN
						else:
							alert("Engine to begin")
							prompt_engine()
				ERROR:
					alert("Lost connection to Chess Engine!")
					state = IDLE
		PLAYER_TURN:
			match event:
				DONE:
					print(msg)
				MOVE:
					ponder()
					# msg should contain the player move
					show_last_move(msg)
					set_next_color(false)
					prompt_engine(msg)
		ENGINE_TURN:
			match event:
				DONE:
					var move = get_best_move(msg)
					if move != "":
						move_engine_piece(move)
						show_last_move(move)
						set_next_color()
						state = PLAYER_TURN
					# Don't print the info spam
					if !msg.begins_with("info"):
						print(msg)
		PLAYER_WIN:
			match event:
				DONE:
					print("Player won")
					state = IDLE
					set_next_color()
		ENGINE_WIN:
			match event:
				DONE:
					print("Engine won")
					state = IDLE
					set_next_color()


func prompt_engine(move = ""):
	if fen == "":
		engine.send_packet("position startpos moves " + move)
	else:
		fen = board.get_fen("b")
		engine.send_packet("position fen %s moves %s" % [fen, move])
	engine.send_packet("go movetime 1000")
	state = ENGINE_TURN


func stow_taken_piece(p: Piece):
	var tex = TextureRect.new()
	tex.texture = p.obj.texture
	if p.side == "B":
		$VBox/BlackPieces.add_child(tex)
	else:
		$VBox/WhitePieces.add_child(tex)
	p.queue_free()


func show_last_move(move = ""):
	$VBox/HBox/Grid/LastMove.text = move


func get_best_move(s: String):
	var move = ""
	# Make sure that whitespace contains spaces since it may only have tabs for example
	var raw_tokens = s.replace("\t", " ").split(" ")
	var tokens = []
	for t in raw_tokens:
		var tt = t.strip_edges()
		if tt != "":
			tokens.append(tt)
	if tokens.size() > 1:
		if tokens[0] == "bestmove": # This is the engine's move
			move = tokens[1]
	if tokens.size() > 3:
		if tokens[2] == "ponder": # This is the move suggested to the player by the engine following it's best move (so like the engine playing against itself)
			ponder(tokens[3])
	return move


# The engine sends a suggested next move for the player tagged with "ponder"
# So we display this move to the player in the UI or hide the UI elements
func ponder(move = ""):
	if move == "":
		$VBox/HBox/VBox/Ponder.modulate.a = 0
	elif show_suggested_move:
		$VBox/HBox/VBox/Ponder.modulate.a = 1.0
		$VBox/HBox/VBox/Ponder/Move.text = move


func move_engine_piece(move: String):
	var pos1 = board.move_to_position(move.substr(0, 2))
	var p: Piece = board.get_piece_in_grid(pos1.x, pos1.y)
	p.new_pos = board.move_to_position(move.substr(2, 2))
	if move.length() == 5:
		p.promote_to = move[4]
	try_to_make_a_move(p)


func alert(txt, duration = 1.0):
	$c/Alert.open(txt, duration)


# This is called after release of the mouse button and when the mouse
# has crossed the Grid border so as to release any selected piece
func mouse_entered():
	return_piece(selected_piece)


func piece_clicked(piece):
	selected_piece = piece
	# Need to ensure that piece displays above all others when moved
	# The z_index gets reset when we settle the piece back into it's resting position
	piece.obj.z_index = 1
	print("Board clicked ", selected_piece)


func piece_unclicked(piece):
	try_to_make_a_move(piece)


func try_to_make_a_move(piece: Piece):
	var info = board.get_position_info(piece, state != IDLE) # When Idle, we are not playing a game so the user may move the black pieces
	print(info.ok)
	# Try to drop the piece
	# Also check for castling and passant
	var ok_to_move = false
	var rook = null
	if info.ok:
		if info.piece != null:
			ok_to_move = true
		else:
			if info.passant and board.passant_pawn.pos.x == piece.new_pos.x:
				print("passant")
				board.take_piece(board.passant_pawn)
				ok_to_move = true
			else:
				ok_to_move = piece.key != "P" or piece.pos.x == piece.new_pos.x
			if info.castling:
				# Get rook
				var rx
				if piece.new_pos.x == 2:
					rx = 3
					rook = board.get_piece_in_grid(0, piece.new_pos.y)
				else:
					rook = board.get_piece_in_grid(7, piece.new_pos.y)
					rx = 5
				if rook != null and rook.key == "R" and rook.tagged and rook.side == piece.side:
					ok_to_move = !board.is_checked(rx, rook.pos.y, rook.side)
					if ok_to_move:
						# Move rook
						rook.new_pos = Vector2(rx, rook.pos.y)
					else:
						alert("Check")
				else:
					ok_to_move = false
	if info.piece != null:
		ok_to_move = ok_to_move and info.piece.key != "K"
	if ok_to_move:
		if piece.key == "K":
			if board.is_king_checked(piece).checked:
				alert("Cannot move into check position!")
			else:
				if rook != null:
					move_piece(rook, false)
				board.take_piece(info.piece)
				move_piece(piece)
		else:
			board.take_piece(info.piece)
			move_piece(piece)
			var status = board.is_king_checked(piece)
			if status.mated:
				alert("Check Mate!")
				if status.side == "B":
					state = PLAYER_WIN
				else:
					state = ENGINE_WIN
				handle_state(DONE)
			else:
				if status.checked:
					alert("Check")
	return_piece(piece) # Settle the piece precisely into position and reset it's z_order


func move_piece(piece: Piece, not_castling = true):
	var pos = [piece.pos, piece.new_pos]
	board.move_piece(piece)
	if state == PLAYER_TURN:
		moves.append(board.position_to_move(pos[0]) + board.position_to_move(pos[1]))
		if not_castling:
			handle_state(MOVE, moves.join(" ")) # When castling there may be 2 moves to convey rook <> king
			moves = []


func mouse_moved(pos):
	if selected_piece != null:
		selected_piece.obj.position = pos - Vector2(board.square_width, board.square_width) / 2.0


# Return the piece to it's base position after being moved via mouse
# Reset it's z_order and test for the situation of a pawn promotion
func return_piece(piece: Piece):
	if piece != null:
		piece.obj.position = Vector2(0, 0)
		piece.obj.z_index = 0
		selected_piece = null
		if piece.key == "P":
			if piece.side == "B" and piece.pos.y == 7 or piece.side == "W" and piece.pos.y == 0:
				Pieces.promote(piece)


func _on_Start_button_down():
	state = IDLE
	handle_state(NEW_GAME)


func _on_Engine_done(ok, packet):
	if ok:
		handle_state(DONE, packet)
	else:
		handle_state(ERROR)


func _on_Fen_button_down():
	print(board.get_fen("w"))


func _on_CheckBox_toggled(button_pressed):
	show_suggested_move = button_pressed


func _on_Board_fullmove(n):
	$VBox/HBox/Grid/Moves.text = String(n)


func _on_Board_halfmove(n):
	$VBox/HBox/Grid/HalfMoves.text = String(n)
	if n == 50:
		alert("It's a draw!")
		state = IDLE


func reset_board():
	if !board.cleared:
		board.halfmoves = 0
		board.fullmoves = 0
		show_last_move()
		ponder()
		set_next_color()
		state = IDLE
		board.clear_board()
		board.setup_pieces()
		for node in $VBox/WhitePieces.get_children():
			node.queue_free()
		for node in $VBox/BlackPieces.get_children():
			node.queue_free()


func _on_Reset_button_down():
	reset_board()


func _on_Flip_button_down():
	set_next_color(!white_next)


func set_next_color(is_white = true):
	white_next = is_white
	$VBox/HBox/Menu/Next/Color.color = Color.white if white_next else Color.black


func _on_Load_button_down():
	fd.mode = FileDialog.MODE_OPEN_FILE
	fd.popup_centered()


func _on_Save_button_down():
	pass # Replace with function body.


func _on_FileDialog_file_selected(path):
	if fd.mode == FileDialog.MODE_OPEN_FILE:
		var file = File.new()
		file.open(path, File.READ)
		var content = file.get_as_text()
		file.close()
		fen_from_file(content)
	else:
		pass


func fen_from_file(content: String):
	var parts = content.split(",")
	# Find the FEN string
	fen = ""
	for s in parts:
		if "/" in s:
			fen = s
			break
	# Validate it
	if is_valid_fen(fen):
		board.clear_board()
		set_next_color(board.setup_pieces(fen))
	else:
		alert("Invalid FEN string")


func is_valid_fen(_fen: String):
	var n = 0
	var rows = 1
	for ch in _fen:
		if ch == " ":
			break
		if ch == "/":
			rows += 1
		elif ch.is_valid_integer():
			n += int(ch)
		elif ch in "pPrRnNbBqQkK":
			n += 1
	return n == 64 and rows == 8
