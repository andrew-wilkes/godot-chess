extends Control

export var server_exe = ""

var server_pid

func _ready():
	# Check if server file exists
	var file = File.new()
	if !file.file_exists(server_exe):
		breakpoint
	file.close()
	# Start UDP server
	server_pid = OS.execute(server_exe, [], false)
	print("PID of server: %d" % server_pid)
	# Give it time to start
	yield(get_tree(), "idle_frame")
	# Set up the UDP client and send a packet
	$UDPClient.connect_to_server()
	$UDPClient.send_packet("engine dummy-engine")
	$Timer.start()


func _on_UDPClient_got_packet(pkt):
	$Timer.stop()
	print("Recieved: %s" % pkt)


func _on_Timer_timeout():
	print("Timed out! Check that UDP server is running")


func _on_TestUDPClient_tree_exited():
	if OS.kill(server_pid):
		print("Failed to kill server process")
