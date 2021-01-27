extends Control

export var server_exe = ""
export var engine = ""

var server_pid = 0
var counter = 0

func _ready():
	# Check if server file exists
	var file = File.new()
	if !file.file_exists(server_exe):
		breakpoint
	# Check if engine file exists
	if !file.file_exists(engine):
		breakpoint
	file.close()
	# Start UDP server
	server_pid = OS.execute(server_exe, [engine], false)
	print("PID of server: %d" % server_pid)
	# Give it time to start
	yield(get_tree(), "idle_frame")
	# Set up the UDP client and send a packet
	$UDPClient.set_server()
	$UDPClient.send_packet("uci\n")
	$Timer.start()


func _on_UDPClient_got_packet(pkt):
	$Timer.stop()
	print(pkt)
	if pkt == "uciok":
		$UDPClient.send_packet("quit\n")


func _on_Timer_timeout():
	print("Timed out! Check that UDP server is running")
	queue_free()


func _on_tree_exited():
	if OS.kill(server_pid):
		print("Failed to kill server process")
