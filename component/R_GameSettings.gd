@tool
@static_unload
extends Resource
class_name R_GameSettings

@export_group("Users")
@export var VIP: Dictionary = {
	"simusdev": {"os_id": "{0cf30166-12eb-11ef-e1b6-606e6b6e6161}"},
	"zxcvlxd": {"os_id": ""},
}

@export_group("Objects")
@export_dir var objects_path: String = ""

@export_group("Server")
@export var dedicated_server_port: int = 8080

static var _instance: R_GameSettings

static func instance() -> R_GameSettings:
	if !_instance:
		_instance = load("res://game_settings.tres")
	return _instance
