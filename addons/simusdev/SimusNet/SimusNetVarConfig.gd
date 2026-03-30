extends SimusNetConfigBase
class_name SimusNetVarConfig

@export var _channel: int = SimusNetChannels.DEFAULT_ID
@export var _reliable: bool = true

@export var _replication: bool = false
@export var _replicate_on_spawn: bool = false
@export var _serialize: bool = true


enum MODE {
	AUTHORITY,
	SERVER_ONLY,
	TO_SERVER,
}

@export var _mode: MODE = MODE.AUTHORITY

@export var _tickrate: float = 0.0

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

@export var __send_to_owner: bool = false
func flag_send_to_owner(value: bool = false) -> SimusNetVarConfig:
	__send_to_owner = value
	return self

func _is_network_authority(handler: SimusNetVarConfigHandler) -> bool:
	if _mode == MODE.SERVER_ONLY:
		return SimusNetConnection.is_server()
	
	return SimusNet.is_network_authority(handler.get_identity().owner)

func _get_network_authority(handler: SimusNetVarConfigHandler) -> int:
	return SimusNet.get_network_authority(handler.get_identity().owner)

func _validate_send(handler: SimusNetVarConfigHandler, to_peer: int) -> bool:
	if SimusNetConnection.is_server():
		return true
	
	if _mode == MODE.TO_SERVER:
		return to_peer == SimusNet.SERVER_ID
	
	var authority: bool = _is_network_authority(handler)
	
	if authority and __send_to_owner:
		return _get_network_authority(handler) == to_peer
	
	return authority 

func _validate_send_receive(handler: SimusNetVarConfigHandler, from_peer: int) -> bool:
	if from_peer == SimusNetConnection.SERVER_ID:
		return true
	
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
	
	
	var changed_properties: Dictionary[StringName, Variant] = SimusNetSynchronization.get_changed_properties(handler.get_object())
	if handler.get_object():
		for property: String in handler.get_properties_for(self):
			if _reliable:
				if SimusNetVars._hook_snapshot(changed_properties, property, handler.get_object()):
					return
			
			SimusNetVars.send(handler.get_object(), property)

func _network_ready(handler: SimusNetVarConfigHandler) -> void:
	if !handler.get_object():
		return
	
	await _async_apply_channel(_channel)
	
	if _replicate_on_spawn and !_mode == MODE.TO_SERVER:
		for property: String in handler.get_properties_for(self):
			SimusNetVars.replicate(handler.get_object(), property)

func _network_disconnect(handler: SimusNetVarConfigHandler) -> void:
	pass

static func get_configs(object: Object) -> Dictionary[StringName, SimusNetVarConfig]:
	return SimusNetVarConfigHandler.get_or_create(object)._list

static func get_config(object: Variant, property: StringName) -> SimusNetVarConfig:
	if is_instance_valid(object):
		return get_configs(object).get(property)
	return null
