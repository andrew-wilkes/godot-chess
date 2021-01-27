extends Node

class_name Engine

var iopiper
var engine

func _ready():
	# Get the base path of the application files
	var output = []
	var _exit_code = OS.execute("pwd", [], true, output)
	var path = output[0].strip_edges()
	var src_pos = path.find("src")
	if src_pos > -1:
		path = path.substr(0, src_pos - 1)
	
	# Form paths to the executables
	iopiper = path + "/bin/iopiper"
	engine = path + "/engine/"

	# Get the first file found in the engine folder
	var dir = Directory.new()
	if dir.open(engine) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		if file_name != "" and !dir.current_is_dir():
			engine += file_name
