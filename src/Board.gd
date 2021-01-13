extends Control

export var square_width = 64
export(Color) var white
export(Color) var grey
export(Color) var mod_color

const num_squares = 64

var grid : PoolStringArray

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_tiles()
	setup_pieces()
	#test_is_white()
	#test_highlight_square()
	#$Grid.get_child(0).add_child(piece.instance())


func setup_pieces():
	var seq = "PPPPPPPPRNBQKBNRPPPPPPPP"
	for i in 16:
		$Grid.get_child(i).add_child(Pieces.get_piece(seq[i + 8], "B"))
		grid[i] = "B" + seq[i + 8]
		$Grid.get_child(i + 48).add_child(Pieces.get_piece(seq[i]))
		grid[i + 48] = "W" + seq[i]


func draw_tiles():
	var white_square = ColorRect.new()
	white_square.color = white
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
				add_square(white_square.duplicate(), [x, y])
			else:
				add_square(grey_square.duplicate(), [x, y])


func add_square(s: ColorRect, xy: Array):
	s.connect("gui_input", self, "square_clicked", xy)
	$Grid.add_child(s)


func square_clicked(event: InputEvent, x: int, y: int):
	if event.is_pressed():
		print("Clicked at: ", [x, y])
		print(get_piece_in_grid(x, y))


func get_piece_in_grid(x: int, y: int):
	var p = grid[x + 8 * y]
	return p


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
		if is_white(n):
			sqr.color = white
		else:
			sqr.color = grey


func test_is_white():
	for n in num_squares:
		if $Grid.get_child(n).color == white:
			assert(is_white(n))
		else:
			assert(!is_white(n))


func is_white(n: int):
# warning-ignore:integer_division
	return 0 == ((n / 8) + n) % 2
