class_name SimusNetServerBroadcaster extends RefCounted

var broadcasting: bool = false:
	set(value):
		broadcasting = value
		if is_instance_valid(_timer):
			if broadcasting:
				_timer.start()
			else:
				_timer.stop()

var _logger:SD_Logger

var server_info:SimusNetServerInfo
var socketUDP: PacketPeerUDP
var _cached_packet: PackedByteArray
var _timer:Timer

func _init(p_server_info:SimusNetServerInfo) -> void:
	_logger = SD_Logger.new("SimusNetServerBroadcaster")
	if not p_server_info:
		_logger.debug("server_info is null", SD_ConsoleCategories.CATEGORY.ERROR)
		return
	
	server_info = p_server_info
	
	socketUDP = PacketPeerUDP.new()
	socketUDP.set_broadcast_enabled(true)
	socketUDP.set_dest_address('255.255.255.255', server_info.broadcasting_port)
	
	_timer = Timer.new()
	_timer.wait_time = server_info.broadcasting_interval
	_timer.timeout.connect(broadcast)
	Engine.get_main_loop().root.add_child.call_deferred(_timer)
	
	_prepare_packet()

func _prepare_packet():
	var packet_data = server_info.get_as_dictionary()
	
	packet_data.erase("icon") 
	
	if DisplayServer.get_name() != "headless":
		var img_path = server_info.icon.resource_path if server_info.icon else ""
		if img_path != "" and FileAccess.file_exists(img_path):
			var img = Image.load_from_file(img_path)
			if img:
				img.resize(64, 64, Image.INTERPOLATE_TRILINEAR)
				packet_data["image_data"] = img.save_jpg_to_buffer(0.75)
	
	_cached_packet = var_to_bytes(packet_data)

func broadcast():
	if not broadcasting: return
	if _cached_packet.is_empty():
		_prepare_packet()
	socketUDP.put_packet(_cached_packet)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_timer):
			_timer.queue_free()
		socketUDP.close()
