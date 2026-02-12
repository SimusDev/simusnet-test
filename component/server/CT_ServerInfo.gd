extends Node
class_name CT_ServerInfo

var _config: ConfigFile = ConfigFile.new()

const CONFIG_PATH: String = "user://server_info.ini"

const INFO_KEYS: Dictionary = {
	"name": "My Server",
	"description": "My Description.",
	"image": "image.png",
	"web_site": "",
}

func _ready() -> void:
	var path: String = SD_FileSystem.normalize_path(CONFIG_PATH)
	_config.load(path)
	
	var init: int = 0
	for key in INFO_KEYS:
		if !_config.has_section_key("info", key):
			init += 1
			_config.set_value("info", key, INFO_KEYS[key])
	
	if init > 0:
		_config.save(path)
