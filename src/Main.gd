extends Control

var selected_piece
var pawn_first_move2 # needed for en passant detection
var board
var engine
var pid = 0
var moves: PoolStringArray
var fen = "r1b1k2r/5pp1/p3p2p/2b4P/2BnnKP1/1P41q/P1PP4/1RBQ4 w qk - 43 21"

enum { IDLE, CONNECTING, STARTING, PLAYER_TURN, ENGINE_TURN, PLAYER_WIN, ENGINE_WIN } # states
var state = IDLE
enum { CONNECT, NEW_GAME, DONE, ERROR, MOVE } # events

func _ready():
	board = find_node("Board")
	board.connect("clicked", self, "piece_clicked")
	board.connect("unclicked", self, "piece_unclicked")
	board.connect("moved", self, "mouse_moved")
	board.get_node("Grid").connect("mouse_exited", self, "mouse_entered")
	engine = $Engine
	ponder()


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
					board.halfmoves = 0
					board.fullmoves = 0
					if !board.cleared:
						board.clear_board()
						board.setup_pieces()
					if engine.server_pid > 0:
						engine.send_packet("ucinewgame")
						engine.send_packet("isready")
						alert("Please make your move")
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
						state = PLAYER_TURN
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
					if fen == "":
						engine.send_packet("position startpos moves " + msg)
					else:
						fen = board.get_fen("b")
						print(fen)
						engine.send_packet("position fen %s moves %s" % [fen, msg])
					engine.send_packet("go movetime 1000")
					state = ENGINE_TURN
		ENGINE_TURN:
			match event:
				DONE:
					var move = get_best_move(msg)
					if move != "":
						move_engine_piece(move)
						state = PLAYER_TURN
					print(msg)
		PLAYER_WIN:
			match event:
				DONE:
					print("Player won")
		ENGINE_WIN:
			match event:
				DONE:
					print("Engine won")


func get_best_move(s: String):
	var move = ""
	# Make sure that whitespace contains spaces
	var raw_tokens = s.replace("\t", " ").split(" ")
	var tokens = []
	for t in raw_tokens:
		var tt = t.strip_edges()
		if tt != "":
			tokens.append(tt)
	if tokens.size() > 1:
		if tokens[0] == "bestmove":
			move = tokens[1]
	if tokens.size() > 3:
		if tokens[2] == "ponder":
			ponder(tokens[3])
	return move


func ponder(move = ""):
	if move == "":
		$HBox/VBox/Ponder.modulate.a = 0
	else:
		$HBox/VBox/Ponder.modulate.a = 1.0
		$HBox/VBox/Ponder/Move.text = move


func move_engine_piece(move: String):
	var pos1 = board.move_to_position(move.substr(0, 2))
	var p: Piece = board.get_piece_in_grid(pos1.x, pos1.y)
	p.new_pos = board.move_to_position(move.substr(2, 2))
	drop_piece(p)


func alert(txt, duration = 1.0):
	$c/Alert.open(txt, duration)


# This is called after release of the mouse button and when the mouse
# crosses the Grid border so as to release any selected piece
func mouse_entered():
	return_piece(selected_piece)


func piece_clicked(piece):
	selected_piece = piece
	# Need to ensure that piece displays above all others when moved
	piece.obj.z_index = 1
	print("Board clicked ", selected_piece)


func piece_unclicked(piece):
	drop_piece(piece)


func drop_piece(piece: Piece):
	var info = board.get_position_info(piece)
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
	return_piece(piece)


func move_piece(piece: Piece, not_castling = true):
	var pos = [piece.pos, piece.new_pos]
	board.move_piece(piece)
	if state == PLAYER_TURN:
		moves.append(board.position_to_move(pos[0]) + board.position_to_move(pos[1]))
		if not_castling:
			handle_state(MOVE, moves.join(" "))
			moves = []


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


func return_piece(piece: Piece):
	if piece != null:
		# Return the piece to it's base position after being moved via mouse
		piece.obj.position = Vector2(0, 0)
		piece.obj.z_index = 0
		selected_piece = null


func _on_Start_button_down():
	handle_state(NEW_GAME)


func _on_Engine_done(ok, packet):
	if ok:
		handle_state(DONE, packet)
	else:
		handle_state(ERROR)
