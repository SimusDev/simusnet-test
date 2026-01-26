@tool
@static_unload
extends Resource
class_name R_GameSettings

@export_dir var objects_path: String = ""

@export_group("Server")
@export var dedicated_server_port: int = 8080

static var _instance: R_GameSettings

static func instance() -> R_GameSettings:
	if !_instance:
		_instance = load("res://game_settings.tres")
	return _instance
