class_name SimusNetServerListener extends Node

signal server_discovered(server_info: Dictionary)
signal server_removed(ip: String)

var simusnet_settings:SimusNetSettings

var _udp: PacketPeerUDP = PacketPeerUDP.new()
var _servers: Dictionary = {} 
var _tick_timer:Timer
var _cleanup_timer: Timer

var should_listen:bool = true
var listening:bool = true

func _ready():
	simusnet_settings = SimusNetSettings.get_or_create()
	
	var parent = get_parent()
	if parent is Control:
		parent.visibility_changed.connect(_update)
		_update()
		
		while not parent.visible:
			await parent.visibility_changed
	
	if SimusNetConnection.is_dedicated_server():
		return
	_servers.clear()
	
	var broadcasting_port:int = simusnet_settings.server_info.broadcasting_port
	var err = _udp.bind(broadcasting_port)
	if err != OK:
		push_error("SimusNetServerListener: Failed to bind UDP port %d. Error code: %d" % [broadcasting_port, err])
		return
	
	_tick_timer = Timer.new()
	_tick_timer.wait_time = simusnet_settings.server_info.listener_listening_interval
	_tick_timer.one_shot = false
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_tick)
	add_child(_tick_timer)
	
	# Setup cleanup timer
	_cleanup_timer = Timer.new()
	_cleanup_timer.wait_time = simusnet_settings.server_info.listener_cleanup_interval
	_cleanup_timer.one_shot = false
	_cleanup_timer.autostart = true
	_cleanup_timer.timeout.connect(_cleanup)
	add_child(_cleanup_timer)

func _update() -> void:
	
	var parent = get_parent()
	if parent is Control:
		should_listen = parent.visible
	

func _tick() -> void:
	if SimusNetConnection.is_dedicated_server():
		return
	
	if not (listening and should_listen):
		return

	
	while _udp.get_available_packet_count() > 0:
		var packet_ip: String = _udp.get_packet_ip()
		var packet_port: int = _udp.get_packet_port()
		var packet_data: PackedByteArray = _udp.get_packet()
		
		if packet_ip.is_empty() or packet_port <= 0:
			continue
		
		# Deserialize the packet data
		var server_info: Dictionary
		var deserialize_ok = false
		if packet_data.size() > 0:
			var deserialized = bytes_to_var(packet_data)
			if deserialized is Dictionary:
				server_info = deserialized
				deserialize_ok = true
		
		if not deserialize_ok:
			# Invalid data, ignore this packet
			continue
		
		if server_info.has("image_data"):
			if not DisplayServer.get_name() == "headless":
				var img = Image.new()
				var error = img.load_jpg_from_buffer(server_info["image_data"])
				if error == OK:
					server_info["texture"] = ImageTexture.create_from_image(img)
		
		var required_fields = ["port", "name"]
		var missing = false
		for field in required_fields:
			if not server_info.has(field):
				missing = true
				break
		if missing:
			continue
		
		# Add or update server entry
		var now = Time.get_unix_time_from_system()
		server_info["ip"] = packet_ip
		server_info["last_seen"] = now
		
		if not _servers.has(packet_ip):
			# New server discovered
			_servers[packet_ip] = server_info
			server_discovered.emit(server_info)
			SimusDev.console.write_info("[SimusNetServerListener] Found Server '%s'" % packet_ip)
		else:
			# Update existing server info (optional: merge only last_seen and maybe other fields)
			var existing = _servers[packet_ip]
			existing.merge(server_info, true)  # overwrite fields from new packet
			existing["last_seen"] = now


func _cleanup():
	var now = Time.get_unix_time_from_system()
	var to_remove: Array[String] = []
	
	for ip in _servers:
		var last_seen = _servers[ip].get("last_seen", 0)
		if now - last_seen > simusnet_settings.server_info.listener_server_timeout:
			to_remove.append(ip)
	
	for ip in to_remove:
		_servers.erase(ip)
		server_removed.emit(ip)


func _exit_tree():
	if _udp:
		_udp.close()
	if _cleanup_timer:
		_cleanup_timer.stop()


func broadcast_discovery_request(broadcast_port: int = 4242, message: Variant = "DISCOVER"):
	var broadcast_address = "255.255.255.255"  # or use network interface broadcast
	var data = var_to_bytes(message)
	_udp.set_broadcast_enabled(true)
	_udp.put_var(data)
	_udp.put_packet(data)
	_udp.set_broadcast_enabled(false)
