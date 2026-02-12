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

signal on_update_received()

var _last: R_ServerInfo

func get_last() -> R_ServerInfo:
	return _last

func _ready() -> void:
	SimusNetIdentity.register(self)
	var path: String = SD_FileSystem.normalize_path(CONFIG_PATH)
	_config.load(path)
	
	var init: int = 0
	for key in INFO_KEYS:
		if !_config.has_section_key("info", key):
			init += 1
			_config.set_value("info", key, INFO_KEYS[key])
	
	if init > 0:
		_config.save(path)
	
	SimusNetRPC.register(
		[
			
			_request_update_rpc
			
		], SimusNetRPCConfig.new().flag_mode_to_server()
	)
	
	SimusNetRPC.register(
		[
			
			_receive_update_rpc,
			
		], SimusNetRPCConfig.new().flag_mode_server_only()
	)

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
		SimusNetRPC.invoke_on_sender(_receive_update_rpc, data)

func _receive_update_rpc(data: Dictionary) -> void:
	var info: R_ServerInfo = R_ServerInfo.new()
	info._cfg_data = data
	_last = info
	on_update_received.emit()
	
