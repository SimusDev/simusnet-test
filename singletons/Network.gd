extends Node

@onready var CHANNEL_USERS: String = SimusNetChannels.register("users")
@onready var CHANNEL_INVENTORY: String = SimusNetChannels.register("inventory")
@onready var CHANNEL_INTERACTABLES: String = SimusNetChannels.register("interactables")
@onready var CHANNEL_STATES: String = SimusNetChannels.register("states")
@onready var CHANNEL_ENVIRONMENT: String = SimusNetChannels.register("environment")

const MAX_PLAYERS: int = 1000
const DEFAULT_PORT: int = 8080

var server_info: CT_ServerInfo

static var server_broadcaster:SimusNetServerBroadcaster

func _ready() -> void:
	server_info = CT_ServerInfo.new()
	server_info.name = "server_info"
	add_child(server_info)
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)
	var commands_exec: Array[SD_ConsoleCommand] = [
		SD_ConsoleCommand.get_or_create("connect"),
		SD_ConsoleCommand.get_or_create("disconnect"),
		SD_ConsoleCommand.get_or_create("start.server"),
		SD_ConsoleCommand.get_or_create("start.dedicated")
	]
	
	for i in commands_exec:
		i.executed.connect(_on_cmd_executed.bind(i))
	
	if OS.has_feature("dedicated_server"):
		create_server(DEFAULT_PORT)

func _on_connected() -> void:
	SD_Console.i().write_info("connected to server.")

func _on_disconnected() -> void:
	SD_Console.i().write_info("disconnected from server.")

func _on_cmd_executed(cmd: SD_ConsoleCommand) -> void:
	match cmd.get_code():
		"connect":
			connect_to_server_by_address(cmd.get_value())
		"disconnect":
			try_disconnect()
		"start.server":
			if cmd.get_arguments().size() < 1:
				cmd.get_console().write_error("please, set the port.")
				return
			create_server(cmd.get_value_as_int())
		"start.dedicated":
			if cmd.get_arguments().size() < 1:
				cmd.get_console().write_error("please, set the port.")
				return
			create_server(cmd.get_value_as_int(), true)

func try_disconnect() -> void:
	SimusNetConnection.try_close_peer()
	
	if is_instance_valid(server_broadcaster):
		server_broadcaster.queue_free()

func connect_to_server(ip: String, port: int = DEFAULT_PORT) -> void:
	SimusNetConnectionENet.create_client(ip, port)

func connect_to_server_by_address(address: String) -> void:
	var parsed: PackedStringArray = address.split(":")
	if parsed.size() == 2:
		connect_to_server(parsed[0], int(parsed[1]))
	return

func create_server(port: int = -1, dedicated: bool = false) -> void:
	if port < 0:
		var cfg_port = server_info._config.get_value("info", "port", -2)
		if cfg_port is int:
			port = cfg_port
		elif cfg_port is String:
			if cfg_port.is_valid_int():
				cfg_port = int(cfg_port)
		if port < 0:
			SimusDev.console.write_error("Failed to create server with this port %s" % port)
			return
	
	
	SimusNetConnection.set_dedicated_server(dedicated)
	SimusNetConnectionENet.create_server(port, MAX_PLAYERS)
	
	server_info._request_update_rpc()
	
	if is_instance_valid(server_broadcaster):
		if not server_info._config:
			return
	if !server_broadcaster:
		server_broadcaster = SimusNetServerBroadcaster.new()
	
	server_broadcaster.serverInfo = server_info.get_last().get_data()
	if not server_broadcaster.is_inside_tree():
		add_child(server_broadcaster)
