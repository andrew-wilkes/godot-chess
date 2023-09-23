extends Control

@export var server_exe = ""
@export var engine = ""

var server_pid
var counter = 0

func _ready():
	# Check if server file exists
	#var file = File.new()
	if !FileAccess.file_exists(server_exe):
		breakpoint
	# Check if engine file exists
	if !FileAccess.file_exists(engine):
		breakpoint
	#file.close()
	# Start UDP server
	server_pid = OS.create_process(server_exe, [engine], false)
	print("PID of server: %d" % server_pid)
	# Give it time to start
	#await get_tree().idle_frame
	# Set up the UDP client and send a packet
	$UDPClient.set_server()
	$UDPClient.send_packet("help")
	$Timer.start()


func _on_UDPClient_got_packet(pkt):
	$Timer.stop()
	print("Received: %s" % pkt)
	counter += 1
	await get_tree().create_timer(1.0).timeout
	$UDPClient.send_packet("%d\n" % counter)


func _on_Timer_timeout():
	print("Timed out! Check that UDP server is running")
	queue_free()


func _on_TestUDPClient_tree_exited():
	if OS.kill(server_pid):
		print("Failed to kill server process")
