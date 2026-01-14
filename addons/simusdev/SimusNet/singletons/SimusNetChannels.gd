extends SimusNetSingletonChild
class_name SimusNetChannels

const MAX: int = 72

signal on_channel_cached(channel: String, id: int)
signal on_channel_uncached(channel: String, id: int)

var _channel_cached: String = ""
var _channel_uncached: String = ""

enum BUILTIN {
	HANDSHAKE = MAX,
	CACHE,
	REGISTER,
	IDENTITY,
	VISIBILITY,
	TIME,
	SCENE_REPLICATION,
	TRANSFORM,
	VARS,
	VARS_RELIABLE,
	VARS_SEND,
	VARS_SEND_RELIABLE,
}

const DEFAULT: String = ""
const DEFAULT_ID: int = 0

static var _instance: SimusNetChannels

func initialize() -> void:
	_instance = self
	
	register(DEFAULT)

static func parse_and_get_id(channel: Variant) -> int:
	if channel is int:
		return channel
	if channel is String:
		return get_id(channel)
	return DEFAULT_ID

static func async_parse_and_get_id(channel: Variant) -> int:
	if channel is int:
		return channel
	
	if channel is String:
		var founded: int = get_list().find(channel)
		if founded < 0:
			await _instance.on_channel_cached
			if _instance._channel_cached == channel:
				return get_list().find(channel)
			async_parse_and_get_id(channel)
		return founded
	
	
	return DEFAULT_ID

static func get_list() -> PackedStringArray:
	return SimusNetCache.data_get_or_add("cns", PackedStringArray())

static func get_id(channel: String) -> int:
	var founded: int = get_list().find(channel)
	if founded < 0:
		founded = 0
	return founded

static func get_name_by_id(id: int) -> String:
	return get_list().get(id)

static func register(c_name: String) -> String:
	if get_list().has(c_name):
		return c_name
	
	if get_list().size() >= MAX:
		_instance.logger.debug_error("cant create channel (%s), reached max channels limit(%s)!" % [c_name, MAX])
		return c_name
	
	if SimusNetConnection.is_server():
		_instance._register_rpc.rpc(c_name)
	return c_name

@rpc("authority", "call_local", "reliable", BUILTIN.REGISTER)
func _register_rpc(c_name: String) -> void:
	if get_list().has(c_name):
		return
	
	get_list().append(c_name)
	_channel_cached = c_name
	on_channel_cached.emit(c_name, get_list().find(c_name))
	logger.push_warning("channel registered: %s" % c_name)

static func unregister(c_name: String) -> void:
	if SimusNetConnection.is_server():
		_instance._unregister_rpc.rpc(c_name)

@rpc("authority", "call_local", "reliable", BUILTIN.REGISTER)
func _unregister_rpc(c_name: String) -> void:
	var id: int = get_list().find(c_name)
	get_list().erase(c_name)
	_channel_uncached = c_name
	on_channel_uncached.emit(c_name, id)
