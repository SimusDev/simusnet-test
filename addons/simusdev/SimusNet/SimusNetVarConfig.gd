extends RefCounted
class_name SimusNetVarConfig

const _META: StringName = &"simusnet_var_configs"

var _channel: int = SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE
var _reliable: bool = true

var _replication: bool = false
var _replicate_on_spawn: bool = true
var _serialize: bool = false

var is_ready: bool = false
signal on_ready()

enum MODE {
	AUTHORITY,
	SERVER_ONLY,
}

var _mode: MODE = MODE.AUTHORITY

var _object: Object
var _identity: SimusNetIdentity
var _properties: PackedStringArray = []

func get_identity() -> SimusNetIdentity:
	return _identity

func get_object() -> SimusNetObject:
	return _object

func get_properties() -> PackedStringArray:
	return _properties

func flag_replication(on_spawn: bool = true, value: bool = true) -> SimusNetVarConfig:
	_replicate_on_spawn = on_spawn
	_f_rep(value)
	return self

func _f_rep(value: bool = true) -> void:
	if !is_ready:
		await on_ready
	
	_replication = value
	if _replication:
		SimusNetVars.get_instance().on_tick.connect(_on_tick)
	else:
		SimusNetVars.get_instance().on_tick.disconnect(_on_tick)

func flag_serialize(value: bool = true) -> SimusNetVarConfig:
	_serialize = value
	return self

func _async_apply_channel(channel: Variant) -> void:
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

func _validate_send() -> bool:
	return true

func _validate_send_receive(from_peer: int) -> bool:
	return true

func _validate_replicate() -> bool:
	return true

func _validate_replicate_receive(from_peer: int) -> bool:
	return true


func _on_spawn_replicate() -> void:
	if not _replication:
		return
	
	if _replicate_on_spawn:
		SimusNetVars.replicate(_object, _properties, _reliable)

func _on_tick() -> void:
	if !SimusNetConnection.is_server() and _mode == MODE.SERVER_ONLY:
		return
	 
	if !SimusNet.is_network_authority(_object) and _mode == MODE.AUTHORITY:
		return
	
	SimusNetVars.send(_object, _properties, _reliable)
	

func _initialize(object: Object, properties: PackedStringArray) -> void:
	if Engine.is_editor_hint():
		return
	
	for p in properties:
		SimusNetVars.cache(p)
	
	_object = object
	_properties = properties.duplicate()
	
	for p_name in properties:
		get_configs(object).set(p_name, self)
	
	if object is Node:
		if !object.is_node_ready():
			await object.ready
	
	var identity: SimusNetIdentity = SimusNetIdentity.register(object)
	_identity = identity
	if !identity.is_ready:
		await identity.on_ready
	
	_on_spawn_replicate()
	
	is_ready = true
	on_ready.emit()

static func get_configs(object: Object) -> Dictionary[StringName, SimusNetVarConfig]:
	if object.has_meta(_META):
		return object.get_meta(_META)
	var result: Dictionary[StringName, SimusNetVarConfig] = {}
	object.set_meta(_META, result)
	return result

static func get_config(object: Object, property: StringName) -> SimusNetVarConfig:
	return get_configs(object).get(property)
