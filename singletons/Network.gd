extends Node

@onready var CHANNEL_INVENTORY: String = SimusNetChannels.register("inventory")

const MAX_PLAYERS: int = 1000

func _ready() -> void:
	var commands_exec: Array[SD_ConsoleCommand] = [
		SD_ConsoleCommand.get_or_create("connect"),
		SD_ConsoleCommand.get_or_create("disconnect"),
	]
	
	for i in commands_exec:
		i.executed.connect(_on_cmd_executed.bind(i))

func _on_cmd_executed(cmd: SD_ConsoleCommand) -> void:
	match cmd.get_code():
		"connect":
			var parsed: PackedStringArray = cmd.get_value_as_string().split(":")
			if parsed.size() == 2:
				connect_to_server(parsed[0], int(parsed[1]))
			
		"disconnect":
			SimusNetConnection.try_close_peer()

func try_disconnect() -> void:
	SimusNetConnection.try_close_peer()

func connect_to_server(ip: String, port: int) -> void:
	SimusNetConnectionENet.create_client(ip, port)

func create_server(port: int) -> void:
	SimusNetConnectionENet.create_server(port, MAX_PLAYERS)
