class_name SimusNetServerBroadcaster extends Node


@export var broadcast_interval: float = 1.0
var serverInfo:Dictionary = {"name": "LAN Game"}

var _cached_packet: PackedByteArray

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

func _ready() -> void:
	_prepare_packet()

func _prepare_packet():
	var packet_data = serverInfo.duplicate()
	
	if DisplayServer.get_name() != "headless":
		var img_path = serverInfo.get("image", "")
		if img_path != "" and FileAccess.file_exists(img_path):
			var img = Image.load_from_file(img_path)
			if img:
				img.resize(64, 64, Image.INTERPOLATE_TRILINEAR)
				
				var buffer = img.save_jpg_to_buffer(0.75)
				packet_data["image_data"] = buffer
	
	_cached_packet = var_to_bytes(packet_data)

func broadcast():
	if _cached_packet.is_empty():
		_prepare_packet()
	
	socketUDP.put_packet(_cached_packet)

func _exit_tree():
	broadcastTimer.stop()
	if socketUDP != null:
		socketUDP.close()
