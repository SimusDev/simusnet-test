class_name SimusNetServerBroadcaster extends Node


@export var broadcast_interval: float = 1.0
var serverInfo:Dictionary = {"name": "LAN Game"}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := 4241

func _enter_tree():
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.autostart = true
	
	if multiplayer.multiplayer_peer:
		add_child(broadcastTimer)
		broadcastTimer.timeout.connect(broadcast)
		
		socketUDP = PacketPeerUDP.new()
		socketUDP.set_broadcast_enabled(true)
		socketUDP.set_dest_address('255.255.255.255', broadcastPort)
		print("Broadcast started successfully.")
	else:
		print("Broadcast error: Current network peer is not in server mode.")

func broadcast():
	var packetMessage := serverInfo
	var packet := var_to_bytes(packetMessage)
	socketUDP.put_packet(packet)

func _exit_tree():
	broadcastTimer.stop()
	if socketUDP != null:
		socketUDP.close()
