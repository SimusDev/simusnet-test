extends RefCounted
class_name R_ServerInfo

var _cfg_data: Dictionary = {}

var _players: Array[String]
var _ping: int = 0

var _image: ImageTexture

func get_image() -> ImageTexture:
	return _image

func get_ping() -> int:
	return _ping

func get_players() -> Array[String]:
	return _players

func get_name() -> String:
	return _cfg_data.get("name", "")

func get_description() -> String:
	return _cfg_data.get("description", "")

func get_website() -> String:
	return _cfg_data.get("web_site", "")
