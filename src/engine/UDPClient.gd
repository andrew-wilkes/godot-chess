extends Node

signal got_packet

var udp := PacketPeerUDP.new()

# UDP doesn't interact with the server until it sends a packet, so we use a more appropriate name for this function here
func set_server(port = 7070):
	udp.connect_to_host("127.0.0.1", port)

	
func send_packet(pkt: String):
	udp.put_packet(pkt.to_utf8_buffer())


func _process(_delta):
	if udp.get_available_packet_count() > 0:
		emit_signal("got_packet", udp.get_packet().get_string_from_utf8())
