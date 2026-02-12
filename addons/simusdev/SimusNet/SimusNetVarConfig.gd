extends RefCounted
class_name SimusNetVarConfig

var _channel: int = SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE
var _reliable: bool = true

var _replication: bool = false
var _replicate_on_spawn: bool = true
var _serialize: bool = false

enum MODE {
	AUTHORITY,
	SERVER_ONLY,
	TO_SERVER,
}

var _mode: MODE = MODE.AUTHORITY

var _tickrate: float = 0.0

func flag_replication(on_spawn: bool = true, value: bool = true) -> SimusNetVarConfig:
	_replicate_on_spawn = on_spawn
	_f_rep(value)
	return self

func flag_tickrate(ticks: float) -> SimusNetVarConfig:
	_tickrate = ticks
	return self

func _f_rep(value: bool = true) -> void:
	if _replication == value:
		return
	
	_replication = value

func flag_serialization(value: bool = true) -> SimusNetVarConfig:
	_serialize = value
	return self

func _async_apply_channel(channel: Variant) -> void:
	if channel is String:
		SimusNetChannels.register(channel)
	_channel = SimusNetChannels.parse_and_get_id(channel)
	_channel = await SimusNetChannels.async_parse_and_get_id(channel)

func flag_reliable(channel: Variant = SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE) -> SimusNetVarConfig:
	_reliable = true
	_async_apply_channel(channel)
	return self

func flag_unreliable(channel: Variant = SimusNetChannels.BUILTIN.VARS_SEND) -> SimusNetVarConfig:
	_reliable = false
	_async_apply_channel(channel)
	return self

func flag_mode_authority() -> SimusNetVarConfig:
	_mode = MODE.AUTHORITY
	return self

func flag_mode_server_only() -> SimusNetVarConfig:
	_mode = MODE.SERVER_ONLY
	return self

func flag_mode_to_server() -> SimusNetVarConfig:
	_mode = MODE.TO_SERVER
	return self

func _is_network_authority(handler: SimusNetVarConfigHandler) -> bool:
	if _mode == MODE.SERVER_ONLY:
		return SimusNetConnection.is_server()
	
	return SimusNet.is_network_authority(handler.get_identity().owner)

func _get_network_authority(handler: SimusNetVarConfigHandler) -> int:
	return SimusNet.get_network_authority(handler.get_identity().owner)

func _validate_send(handler: SimusNetVarConfigHandler, to_peer: int) -> bool:
	if _mode == MODE.TO_SERVER:
		return to_peer == SimusNet.SERVER_ID
	
	return _is_network_authority(handler)

func _validate_send_receive(handler: SimusNetVarConfigHandler, from_peer: int) -> bool:
	if _mode == MODE.TO_SERVER:
		return SimusNetConnection.is_server()
	
	return _get_network_authority(handler) == from_peer

func _validate_replicate(handler: SimusNetVarConfigHandler) -> bool:
	return true

func _validate_replicate_receive(handler: SimusNetVarConfigHandler, from_peer: int) -> bool:
	return true

func _process_sync(handler: SimusNetVarConfigHandler) -> void:
	if !_replication:
		return
	
	if _mode == MODE.TO_SERVER:
		if SimusNetConnection.is_server():
			return
	
	if _mode == MODE.AUTHORITY and !_is_network_authority(handler):
		return
	
	if _mode == MODE.SERVER_ONLY and !SimusNetConnection.is_server():
		return
	
	if handler.get_object():
		SimusNetVars.send(handler.get_object(), handler.get_properties_for(self), _reliable)

func _network_ready(handler: SimusNetVarConfigHandler) -> void:
	if !handler.get_object():
		return
	
	if _replication and _replicate_on_spawn and !_mode == MODE.TO_SERVER:
		SimusNetVars.replicate(handler.get_object(), handler.get_properties_for(self), _reliable)

func _network_disconnect(handler: SimusNetVarConfigHandler) -> void:
	pass

static func get_configs(object: Object) -> Dictionary[StringName, SimusNetVarConfig]:
	return SimusNetVarConfigHandler.get_or_create(object)._list

static func get_config(object: Variant, property: StringName) -> SimusNetVarConfig:
	if is_instance_valid(object):
		return get_configs(object).get(property)
	return null
