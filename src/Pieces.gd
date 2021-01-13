#tool

extends GridContainer

var keys = "BKNPQR"

func get_piece(key = "P", color = "W"):
	var i = keys.find(key)
	if color == "W":
		i += 6
	var p = get_child(i).duplicate()
	p.position = Vector2(0, 0)
	return p


func _ready():
#	setup()
	visible = false


func setup():
	var dir = Directory.new()
	if dir.open("res://pieces") == OK:
		var files = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.get_extension() == "png":
				files.append(file_name)
			file_name = dir.get_next()
		files.sort()
		print(files)
		var i = 0
		for file in files:
			var sprite = get_child(i)
			sprite.name = file.get_basename()
			var img = load("res://pieces/" + file)
			sprite.texture = img
			sprite.position.x = i *64
			i += 1
