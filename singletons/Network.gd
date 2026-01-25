extends Node

@onready var CHANNEL_USERS: String = SimusNetChannels.register("users")
@onready var CHANNEL_INVENTORY: String = SimusNetChannels.register("inventory")
@onready var CHANNEL_INTERACTABLES: String = SimusNetChannels.register("interactables")
@onready var CHANNEL_ENVIRONMENT: String = SimusNetChannels.register("environment")

const MAX_PLAYERS: int = 1000

func _ready() -> void:
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

func _on_connected() -> void:
	SD_Console.i().write_info("connected to server.")

func _on_disconnected() -> void:
	SD_Console.i().write_info("disconnected from server.")

func _on_cmd_executed(cmd: SD_ConsoleCommand) -> void:
	match cmd.get_code():
		"connect":
			var parsed: PackedStringArray = cmd.get_value_as_string().split(":")
			if parsed.size() == 2:
				connect_to_server(parsed[0], int(parsed[1]))
			
		"disconnect":
			SimusNetConnection.try_close_peer()
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

func connect_to_server(ip: String, port: int) -> void:
	SimusNetConnectionENet.create_client(ip, port)

func create_server(port: int, dedicated: bool = false) -> void:
	SimusNetConnection.set_dedicated_server(dedicated)
	SimusNetConnectionENet.create_server(port, MAX_PLAYERS)
