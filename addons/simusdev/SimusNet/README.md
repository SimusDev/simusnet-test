
example Network.gd singleton:

``` gdscript
#Network.gd singleton
extends Node

@onready var CHANNEL_USERS: String = SimusNetChannels.register("users") #example channel
@onready var CHANNEL_INVENTORY: String = SimusNetChannels.register("inventory") #example channel
@onready var CHANNEL_INTERACTABLES: String = SimusNetChannels.register("interactables") #example channel
@onready var CHANNEL_STATES: String = SimusNetChannels.register("states") #example channel 
@onready var CHANNEL_ENVIRONMENT: String = SimusNetChannels.register("environment") #example channel

var _logger:SD_Logger

var server_broadcaster:SimusNetServerBroadcaster
var simusnet_settings:SimusNetSettings

func _ready() -> void:
	_logger = SD_Logger.new("Network")
	
	
	simusnet_settings = SimusNetSettings.get_or_create()
	server_broadcaster = SimusNetServerBroadcaster.new(
		simusnet_settings.server_info
		)

	
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
		create_server(simusnet_settings.server_info.port)

func _on_connected() -> void:
	SD_Console.i().write_info("connected to server.")

func _on_disconnected() -> void:
	SD_Console.i().write_info("disconnected from server.")

func _on_cmd_executed(cmd: SD_ConsoleCommand) -> void:
	var code = cmd.get_code()
	var args_size:int = cmd.get_arguments().size()
	
	match code:
		"connect":
			connect_to_server_by_address(cmd.get_value())
		"disconnect":
			try_disconnect()
		"start.server":
			if args_size == 0:
				create_server(simusnet_settings.server_info.port)
			elif args_size == 1:
				create_server(cmd.get_value_as_int())
		"start.dedicated":
			if args_size == 0:
				create_server(simusnet_settings.server_info.port)
			elif args_size == 1:
				create_server(cmd.get_value_as_int(), true)

func try_disconnect() -> void:
	SimusNetConnection.try_close_peer()
	if server_broadcaster.broadcasting:
		server_broadcaster.broadcasting = false

func connect_to_server(ip: String, port: int = -1) -> void:
	if port == -1:
		port = simusnet_settings.server_info.port
	SimusNetConnectionENet.create_client(ip, port)

func connect_to_server_by_address(address: String) -> void:
	var parsed: PackedStringArray = address.split(":")
	if parsed.size() == 2:
		connect_to_server(parsed[0], int(parsed[1]))
	return

func create_server(port: int = -1, dedicated: bool = false) -> void:
	if port == -1:
		port = simusnet_settings.server_info.port
	
	SimusNetConnection.set_dedicated_server(dedicated)
	var server:Error = SimusNetConnectionENet.create_server(port, simusnet_settings.server_info.max_players)
	
	if server == OK:
		server_broadcaster.broadcasting = true
	else:
		_logger.debug("Error creating server. Error code: %s" % server)
		pass
```