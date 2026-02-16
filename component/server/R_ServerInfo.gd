extends RefCounted
class_name R_ServerInfo

var _cfg_data: Dictionary = {}

var _players: PackedStringArray
var _ping: int = 0
var _max_players: int = 78

var _image: ImageTexture

func get_data() -> Dictionary:
	return _cfg_data

func get_port() -> int:
	return _cfg_data.get("port", -2)

func get_image() -> ImageTexture:
	return _image

func get_ping() -> int:
	return _ping

func get_players() -> PackedStringArray:
	return _players

func get_max_players() -> int:
	return _max_players

func get_name() -> String:
	return _cfg_data.get("name", "")

func get_description() -> String:
	return _cfg_data.get("description", "")

func get_website() -> String:
	return _cfg_data.get("web_site", "")
