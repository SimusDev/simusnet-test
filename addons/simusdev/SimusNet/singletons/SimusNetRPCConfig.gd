extends SimusNetConfigBase
class_name SimusNetRPCConfig

@export var _channel: int = 0
@export var _transfer_mode: SimusNetRPC.TRANSFER_MODE = SimusNetRPC.TRANSFER_MODE.RELIABLE

var is_ready: bool = false
signal on_ready()

#//////////////////////////////////////////////////////////////

#//////////////////////////////////////////////////////////////

func _initialize(handler: SimusNetRPCConfigHandler, callable: Callable) -> void:
	handler._list_by_name[callable.get_method()] = self
	handler._list_by_unique_id[handler.get_method_unique_id(callable.get_method())] = self
	handler._callables[callable.get_method()] = callable
	
	_initialize_dynamic(handler)

func _initialize_dynamic(handler: SimusNetRPCConfigHandler) -> void:
	flag_set_channel(_channel)
	
	is_ready = true
	on_ready.emit()

func _deinitialize_dynamic(handler: SimusNetRPCConfigHandler) -> void:
	is_ready = false

func _network_ready(handler: SimusNetRPCConfigHandler) -> void:
	_initialize_dynamic(handler)

func _network_disconnect(handler: SimusNetRPCConfigHandler) -> void:
	_deinitialize_dynamic(handler)

#//////////////////////////////////////////////////////////////

static func try_find_in(callable: Callable) -> SimusNetRPCConfig:
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(callable.get_object())
	return handler._list_by_name.get(callable.get_method())

static func _append_to(callable: Callable, config: SimusNetRPCConfig) -> void:
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(callable.get_object())
	config._initialize(handler, callable)


#//////////////////////////////////////////////////////////////

func flag_get_channel_id() -> int:
	return _channel

func flag_get_transfer_mode() -> SimusNetRPC.TRANSFER_MODE:
	return _transfer_mode

func flag_get_transfer_mode_multiplayer_peer() -> MultiplayerPeer.TransferMode:
	if _transfer_mode == SimusNetRPC.TRANSFER_MODE.RELIABLE:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE
	if _transfer_mode == SimusNetRPC.TRANSFER_MODE.UNRELIABLE:
		return MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
	return MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED

#//////////////////////////////////////////////////////////////

func flag_set_channel(channel: Variant) -> SimusNetRPCConfig:
	if channel is String:
		SimusNetChannels.register(channel)
	_f_s_c_async(channel)
	return self

func _f_s_c_async(channel: Variant) -> void:
	_channel = await SimusNetChannels.async_parse_and_get_id(channel)
	_cache_rpc_processor_callable()

func flag_set_transfer_mode(mode: SimusNetRPC.TRANSFER_MODE) -> SimusNetRPCConfig:
	_transfer_mode = mode
	_cache_rpc_processor_callable()
	return self

var _cached_processor_callable: Callable

func _cache_rpc_processor_callable() -> void:
	var function: String = SimusNetRPCProccessor._parse_and_get_function(flag_get_channel_id(), flag_get_transfer_mode())
	_cached_processor_callable = Callable(SimusNetRPC._instance._processor, function)

func get_cached_processor_callable() -> Callable:
	return _cached_processor_callable

#//////////////////////////////////////////////////////////////

func flag_set_unreliable() -> SimusNetRPCConfig:
	_transfer_mode = SimusNetRPC.TRANSFER_MODE.UNRELIABLE
	return self

func flag_set_unreliable_ordered() -> SimusNetRPCConfig:
	_transfer_mode = SimusNetRPC.TRANSFER_MODE.UNRELIABLE_ORDERED
	return self

func flag_set_reliable() -> SimusNetRPCConfig:
	_transfer_mode = SimusNetRPC.TRANSFER_MODE.RELIABLE
	return self

enum MODE {
	SERVER_ONLY,
	TO_SERVER,
	AUTHORITY,
	ANY_PEER,
}

@export var _mode: MODE = MODE.AUTHORITY

func get_mode() -> MODE:
	return _mode

func set_mode(mode: MODE) -> SimusNetRPCConfig:
	_mode = mode
	return self

@export var ___require_ownership: bool = false

func flag_require_ownership(value: bool = false) -> SimusNetRPCConfig:
	___require_ownership = value
	return self

func flag_mode_server_only() -> SimusNetRPCConfig:
	_mode = MODE.SERVER_ONLY
	return self

func flag_mode_to_server() -> SimusNetRPCConfig:
	_mode = MODE.TO_SERVER
	return self

func flag_mode_authority() -> SimusNetRPCConfig:
	_mode = MODE.AUTHORITY
	return self

func flag_mode_any_peer() -> SimusNetRPCConfig:
	_mode = MODE.ANY_PEER
	return self

@export var _simulate: bool = true
func flag_simulate_locally(simulate: bool = true) -> SimusNetRPCConfig:
	_simulate = simulate
	return self

@export var _serialization: bool = true
func flag_serialization(value: bool = true) -> SimusNetRPCConfig:
	_serialization = value
	return self

@export var _async: bool = false
func flag_async(value: bool = true) -> SimusNetRPCConfig:
	_async = value
	return self

#//////////////////////////////////////////////////////////////

func _validate(handler: SimusNetRPCConfigHandler, callable: Callable, to_peer: int = -1) -> bool:
	if !is_ready:
		await on_ready
	
	var network_authority: bool = SimusNet.is_network_authority(handler.get_object())
	
	if _mode == MODE.SERVER_ONLY:
		if (!SimusNetConnection.is_server()):
			SimusNetRPC._instance.logger.debug_error("failed to validate SERVER_ONLY rpc: %s" % callable)
			return false
	
	if ___require_ownership and !network_authority:
		SimusNetRPC._instance.logger.debug_error("failed to validate OWNERSHIP rpc: %s" % callable)
		return false
	
	if _mode == MODE.AUTHORITY:
		if !network_authority:
			SimusNetRPC._instance.logger.debug_error("failed to validate AUTHORITY rpc: %s" % callable)
		return network_authority
	
	if _mode == MODE.TO_SERVER:
		if to_peer != SimusNet.SERVER_ID:
			SimusNetRPC._instance.logger.debug_error("failed to validate TO_SERVER rpc: %s" % callable)
			return false
	
	return true

func _validate_on_recieve(handler: SimusNetRPCConfigHandler, callable: Callable, from_peer: int = -1) -> bool:
	if !is_ready:
		await on_ready
	
	var network_authority: bool = SimusNet.get_network_authority(handler.get_object()) == from_peer
	
	if _mode == MODE.SERVER_ONLY:
		if SimusNetConnection.is_server():
			if SimusNetRemote.sender_id != SimusNetConnection.SERVER_ID:
				SimusNetRPC._instance.logger.debug_error("failed to recieve SERVER_ONLY rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
				return false
	
	if !network_authority and ___require_ownership:
		SimusNetRPC._instance.logger.debug_error("failed to recieve OWNERSHIP rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
		return false
	
	if _mode == MODE.AUTHORITY:
		var a: bool = SimusNet.get_network_authority(handler.get_object()) == SimusNetRemote.sender_id
		if !a:
			SimusNetRPC._instance.logger.debug_error("failed to recieve AUTHORITY rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
		return a
	
	if _mode == MODE.TO_SERVER:
		var s: bool = SimusNetConnection.is_server()
		if !s:
			SimusNetRPC._instance.logger.debug_error("failed to recieve TO_SERVER rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
		return s
	
	return true
