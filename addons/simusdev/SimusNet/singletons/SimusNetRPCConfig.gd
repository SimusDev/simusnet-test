extends Resource
class_name SimusNetRPCConfig

var _handler: SimusNetRPCConfigHandler

var _channel: int = 0
var _transfer_mode: SimusNetRPC.TRANSFER_MODE = SimusNetRPC.TRANSFER_MODE.RELIABLE

var unique_id: int = -1
var unique_id_bytes: PackedByteArray

var is_ready: bool = false
signal on_ready()

var callable: Callable
var object: Object
#//////////////////////////////////////////////////////////////

#//////////////////////////////////////////////////////////////

func _initialize(handler: SimusNetRPCConfigHandler, callable: Callable) -> void:
	self.callable = callable
	self.object = callable.get_object()
	
	_handler = handler
	
	_handler._list_by_name[callable.get_method()] = self
	
	handler._list.set(callable, self)
	
	SimusNetMethods.cache(callable)
	
	#flag_serialization(SimusNetSettings.get_or_create().serialization_deserialization_enable)
	
	unique_id_bytes = await SimusNetMethods.serialize(callable)
	unique_id = SimusNetMethods.get_id(callable)
	
	handler._list_by_unique_id.set(unique_id, self)
	
	is_ready = true
	on_ready.emit()
	

#//////////////////////////////////////////////////////////////

static func try_find_in(callable: Callable) -> SimusNetRPCConfig:
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(callable.get_object())
	return handler._list.get(callable)

static func _append_to(callable: Callable, config: SimusNetRPCConfig) -> void:
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(callable.get_object())
	config._initialize(handler, callable)


#//////////////////////////////////////////////////////////////

func flag_get_channel_id() -> int:
	return _channel

func flag_get_transfer_mode() -> SimusNetRPC.TRANSFER_MODE:
	return _transfer_mode

#//////////////////////////////////////////////////////////////

func flag_set_channel(channel: Variant) -> SimusNetRPCConfig:
	if channel is String:
		SimusNetChannels.register(channel)
	_channel = SimusNetChannels.parse_and_get_id(channel)
	return self

func flag_set_transfer_mode(mode: SimusNetRPC.TRANSFER_MODE) -> SimusNetRPCConfig:
	_transfer_mode = mode
	return self

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
	AUTHORITY,
	ANY_PEER,
}

var _mode: MODE = MODE.AUTHORITY

func get_mode() -> MODE:
	return _mode

func set_mode(mode: MODE) -> SimusNetRPCConfig:
	_mode = mode
	return self

func flag_mode_server_only() -> SimusNetRPCConfig:
	_mode = MODE.SERVER_ONLY
	return self

func flag_mode_authority() -> SimusNetRPCConfig:
	_mode = MODE.AUTHORITY
	return self

func flag_mode_any_peer() -> SimusNetRPCConfig:
	_mode = MODE.ANY_PEER
	return self

var _serialization: bool = false
func flag_serialization(value: bool = true) -> SimusNetRPCConfig:
	_serialization = value
	return self

#//////////////////////////////////////////////////////////////

func _validate() -> bool:
	if !is_ready:
		await on_ready
	
	if _mode == MODE.SERVER_ONLY:
		if (!SimusNetConnection.is_server()):
			SimusNetRPC._instance.logger.debug_error("failed to validate server only rpc: %s" % callable)
			return false
	
	if _mode == MODE.AUTHORITY:
		var a: bool = SimusNet.is_network_authority(object)
		
		if !a:
			SimusNetRPC._instance.logger.debug_error("failed to validate authority rpc: %s" % callable)
		return a
	
	return true

func _validate_on_recieve() -> bool:
	if !is_ready:
		await on_ready
	
	if _mode == MODE.SERVER_ONLY:
		if SimusNetConnection.is_server():
			if SimusNetRemote.sender_id != SimusNetConnection.SERVER_ID:
				SimusNetRPC._instance.logger.debug_error("failed to recieve server only rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
				return false
	
	if _mode == MODE.AUTHORITY:
		var a: bool = SimusNet.get_network_authority(object) == SimusNetRemote.sender_id
		if !a:
			SimusNetRPC._instance.logger.debug_error("failed to recieve authority rpc from peer: %s, %s" % [SimusNetRemote.sender_id, callable])
		return a
	
	
	return true
