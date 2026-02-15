class_name SimusNetServerListener extends Node

signal new_server(info, ip_addr)
signal remove_server(ip_addr)

var cleanUpTimer := Timer.new()
var socketUDP := PacketPeerUDP.new()
@export var listenPort := 4241
var knownServers = {}

@export var server_cleanup_threshold: int = 3

func _init():
	cleanUpTimer.wait_time = server_cleanup_threshold
	cleanUpTimer.one_shot = false
	cleanUpTimer.autostart = true
	cleanUpTimer.timeout.connect(clean_up)
	add_child(cleanUpTimer)

func _ready():
	knownServers.clear()
	
	set_process(false)
	
	var err = socketUDP.bind(listenPort)

func _process(delta):
	if socketUDP.get_available_packet_count() > 0:
		var serverIp = socketUDP.get_packet_ip()
		var serverPort = socketUDP.get_packet_port()
		var array_bytes = socketUDP.get_packet()
		
		if serverIp != '' and serverPort > 0:
			# We've discovered a new server! Add it to the list and let people know
			if not knownServers.has(serverIp):
				var gameInfo = bytes_to_var(array_bytes)
				var game_port = gameInfo.get("port", -1)
				if game_port < 0:
					return 
				gameInfo.ip = serverIp
				gameInfo.lastSeen = Time.get_unix_time_from_system()
				knownServers[serverIp] = gameInfo
				new_server.emit(gameInfo, serverIp, game_port)
			# Update the last seen time
			else:
				var gameInfo = knownServers[serverIp]
				gameInfo.lastSeen =  Time.get_unix_time_from_system()

func clean_up():
	var now = Time.get_unix_time_from_system()
	for serverIp in knownServers:
		var serverInfo = knownServers[serverIp]
		if (now - serverInfo.lastSeen) > server_cleanup_threshold:
			knownServers.erase(serverIp)
			remove_server.emit(serverIp)

func _exit_tree():
	socketUDP.close()
