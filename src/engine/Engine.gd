extends Node

class_name Engine

# Provide functionality for interactions with a Chess Engine
# Also, find the installed exe files rather than needing UI entry by user

var iopiper # Path of UDP to CLI app bridge in the bin directory
var engine # Path of installed Chess Engine in the engine directory

func _ready():
	# Get the base path of the application files
	var output = []
	var _exit_code = OS.execute("pwd", [], true, output)
	var path = output[0].strip_edges() # Seem to get a null termination char
	# Allow for running in dev mode, so back peddle from src folder
	var src_pos = path.find("src")
	if src_pos > -1:
		path = path.substr(0, src_pos - 1)
	
	# Form paths to the executables
	# Use forward slash for all platforms
	iopiper = path + "/bin/iopiper"
	engine = path + "/engine/"

	# Get the first file found in the engine folder for the Chess Engine to use
	var dir = Directory.new()
	if dir.open(engine) == OK:
		dir.list_dir_begin(true)
		engine += dir.get_next()
	
	# We will ignore the possibility of bad file paths here
