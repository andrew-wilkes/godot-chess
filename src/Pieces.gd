#tool

extends GridContainer

var keys = "BKNPQR" # Bishop King kNight Pawn Queen Rook

# Return a chess piece object defaulting to a White Pawn
func get_piece(key = "P", side = "W"):
	var i = keys.find(key)
	if side == "W":
		i += 6
	var p = get_child(i).duplicate()
	p.position = Vector2(0, 0)
	return p


func promote(p: Piece, promote_to = "q"):
	p.key = promote_to.to_upper()
	var parent = p.obj.get_parent()
	p.obj.queue_free() # Delete pawn
	# Now add the new piece in place of the pawn
	p.obj = get_piece(p.key, p.side)
	parent.add_child(p.obj)


# Edit this to start in the game or as a Tool script when the scene is loaded
func _ready():
#	setup()
	visible = false # It is set up as an Autoloaded scene so want to hide it


# This function is used in Tool script mode to set up the 12 Grid child nodes
# It's useful when you change the child node type or the images to save time
func setup():
	# First create a sorted list of the chess piece images
	var dir = DirAccess.open("res://pieces")
	if dir != null:
		var files = []
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.get_extension() == "png":
				files.append(file_name)
			file_name = dir.get_next()
		files.sort()
		print(files)
		# Now apply the images to the sprite textures
		var i = 0
		for file in files:
			var sprite = get_child(i)
			sprite.name = file.get_basename()
			var img = load("res://pieces/" + file)
			sprite.texture = img
			sprite.position.x = i *64
			i += 1
