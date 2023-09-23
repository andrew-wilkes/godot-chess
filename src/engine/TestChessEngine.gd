extends Control

func _ready():
	var status = $Engine.start_udp_server()
	if status.started:
		print("PID of server: %d" % $Engine.server_pid)
		await get_tree().idle_frame
		$Engine.send_packet("uci")
	else:
		print(status.error)


func _on_Engine_done(ok, packet):
	print(ok, "\t", packet)
	if packet == "uciok":
		print("OK")
