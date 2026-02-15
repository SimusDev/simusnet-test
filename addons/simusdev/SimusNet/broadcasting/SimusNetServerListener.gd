class_name SimusNetServerListener extends Node

# Signals emitted when a server is discovered or removed.
# The dictionary passed contains: "ip", "port", "name", "player_count", "max_players", "last_seen"
signal server_discovered(server_info: Dictionary)
signal server_removed(ip: String)

@export var listen_port: int = 4241
@export var cleanup_interval: float = 3.0
@export var server_timeout: float = 5.0

var _udp: PacketPeerUDP = PacketPeerUDP.new()
var _servers: Dictionary = {}  # key: ip (String), value: Dictionary with server info
var _cleanup_timer: Timer

func _ready():
	_servers.clear()
	
	# Setup UDP socket
	var err = _udp.bind(listen_port)
	if err != OK:
		push_error("SimusNetServerListener: Failed to bind UDP port %d. Error code: %d" % [listen_port, err])
		return
	
	
	# Setup cleanup timer
	_cleanup_timer = Timer.new()
	_cleanup_timer.wait_time = cleanup_interval
	_cleanup_timer.one_shot = false
	_cleanup_timer.autostart = true
	_cleanup_timer.timeout.connect(_cleanup)
	add_child(_cleanup_timer)
	
	set_process(true)


func _process(_delta):
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
		
		# Validate required fields
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
		if now - last_seen > server_timeout:
			to_remove.append(ip)
	
	for ip in to_remove:
		_servers.erase(ip)
		server_removed.emit(ip)


func _exit_tree():
	if _udp:
		_udp.close()
	if _cleanup_timer:
		_cleanup_timer.stop()


# Optional: send a broadcast discovery request to actively solicit servers.
func broadcast_discovery_request(broadcast_port: int = 4242, message: Variant = "DISCOVER"):
	var broadcast_address = "255.255.255.255"  # or use network interface broadcast
	var data = var_to_bytes(message)
	_udp.set_broadcast_enabled(true)
	_udp.put_var(data)
	_udp.put_packet(data)
	_udp.set_broadcast_enabled(false)
