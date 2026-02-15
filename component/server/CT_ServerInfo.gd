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
}

signal on_update_received()

var _image: Image

var _last: R_ServerInfo

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
	
	_image.compress(Image.COMPRESS_ETC2)
	

func request_update() -> CT_ServerInfo:
	if !SimusNetConnection.is_active():
		return
	
	SimusNetRPC.invoke_on_server(_request_update_rpc)
	return self

func _request_update_rpc() -> void:
	var data: Dictionary = {}
	for key in INFO_KEYS:
		if _config.has_section_key("info", key):
			data.set(key, _config.get_value("info", key))
	
	if !data.is_empty():
		SimusNetRPC.invoke_on_sender(_receive_update_rpc, data, _image)

func _receive_update_rpc(data: Dictionary, image: Image) -> void:
	var info: R_ServerInfo = R_ServerInfo.new()
	info._image = ImageTexture.create_from_image(image)
	info._cfg_data = data
	_last = info
	on_update_received.emit()
	
