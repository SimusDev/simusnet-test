extends Node
class_name CT_ServerInfo

var _config: ConfigFile = ConfigFile.new()

const CONFIG_PATH: String = "user://server_info.ini"

const INFO_KEYS: Dictionary = {
	"port": 7878,
	"name": "My Server",
	"description": "My Description.",
	"image": "icon.svg",
	"web_site": "https://contract.gosuslugi.ru/",
	"server_content": "res://local_data/server/content/",
	"max_players": 32,
}

signal on_update_received()

var _image: Image

var _last: R_ServerInfo

var is_headless:bool = DisplayServer.get_name() == "headless"

func get_last() -> R_ServerInfo:
	return _last

func _ready() -> void:
	SimusNetRPC.register(
		[
			
			_request_update_rpc
			
		], SimusNetRPCConfig.new().flag_mode_to_server()
	)
	
	SimusNetRPC.register(
		[
			
			_receive_update_rpc,
			
		], SimusNetRPCConfig.new().flag_mode_server_only().flag_set_channel("server_info").flag_serialization()
	)
	
	reload_config()

func reload_config() -> void:
	var path: String = SD_FileSystem.normalize_path(CONFIG_PATH)
	_config.load(path)
	
	var init: int = 0
	for key in INFO_KEYS:
		if !_config.has_section_key("info", key):
			init += 1
			_config.set_value("info", key, INFO_KEYS[key])
	
	if init > 0:
		_config.save(path)
	
	var image_path: String = SD_FileSystem.normalize_path("user://").path_join(_config.get_value("info", "image", ""))
	_image = Image.load_from_file(image_path)
	if !is_instance_valid(_image):
		return
	
	_image.resize(256, 256)
	if is_headless:
		return
	_image.compress(Image.COMPRESS_ETC2)
	

var _request_time: int = 0

func request_update() -> CT_ServerInfo:
	if !SimusNetConnection.is_active():
		return
	
	_request_time = Time.get_ticks_msec()
	
	SimusNetRPC.invoke_on_server(_request_update_rpc)
	return self

func _request_update_rpc() -> void:
	var data: Dictionary = {}
	for key in INFO_KEYS:
		if _config.has_section_key("info", key):
			data.set(key, _config.get_value("info", key))
	
	var p: PackedStringArray
	for user in CT_User.get_list():
		p.append(user.get_nickname())
	
	data._players = p
	
	if !data.is_empty():
		SimusNetRPC.invoke_on_sender(_receive_update_rpc, data, _image)

func _receive_update_rpc(data: Dictionary, image: Image) -> void:
	if is_headless:
		return
	
	var info: R_ServerInfo = R_ServerInfo.new()
	info._ping = Time.get_ticks_msec() - _request_time
	info._max_players = data.max_players
	info._image = ImageTexture.create_from_image(image)
	info._cfg_data = data
	_last = info
	
	info._players = data._players
	
	on_update_received.emit()
	
