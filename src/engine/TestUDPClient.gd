extends Control

func _ready():
	# Run the server
	var pid = OS.execute("ping-server", [], false)
	print("PID of server: %d" % pid)
	# Send the name of the engine file to the server
	$UDPClient.connect_to_server()
	$UDPClient.send_packet("engine dummy-engine")
	$Timer.start()


func _on_UDPClient_got_packet(pkt):
	$Timer.stop()
	print("Recieved: %s" % pkt)


func _on_Timer_timeout():
	print("Timed out! Check that UDP server is running")
