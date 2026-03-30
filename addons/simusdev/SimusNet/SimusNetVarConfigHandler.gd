extends RefCounted
class_name SimusNetVarConfigHandler

const _META: StringName = &"simusnet_var_config"

var _object_weak_ref: WeakRef
var _identity_weak_ref: WeakRef

var _list: Dictionary[StringName, SimusNetVarConfig] = {}
var _properties_for: Dictionary[SimusNetVarConfig, PackedStringArray]

var _properties_time: Dictionary[int, float] = {}

var current_received_property: String
var current_received_value: Variant
var current_peer: int = 1

signal on_property_received(property: String, peer: int)


func get_all_properties() -> PackedStringArray:
	var result: PackedStringArray = []
	for i in _list:
		result.append(i)
	return result

func get_properties_for(cfg: SimusNetVarConfig) -> PackedStringArray:
	return _properties_for.get(cfg, PackedStringArray())

func get_object() -> Object:
	if _object_weak_ref:
		return _object_weak_ref.get_ref() 
	return null

func get_identity() -> SimusNetIdentity:
	if _identity_weak_ref:
		return _identity_weak_ref.get_ref()
	return null

func get_property_unique_id(property: StringName) -> int:
	return _list.keys().find(property)

func get_property_name_by_unique_id(id: int) -> StringName:
	return _list.keys().get(id)

func _add_cfg(cfg: SimusNetVarConfig, property: StringName) -> void:
	_list[property] = cfg
	
	var properties: PackedStringArray = _properties_for.get_or_add(cfg, PackedStringArray())
	if !property in properties:
		properties.append(property)
		#SimusNetVars.cache(property)
	
	if SimusNetConnection.is_active():
		cfg._network_ready(self)

func _initialize() -> void:
	SimusNetVars.get_instance().on_tick.connect(_tick)
	SimusNetEvents.event_disconnected.listen(_deinitialize_dynamic)
	_initialize_dynamic()

func _initialize_dynamic() -> void:
	if !SimusNetConnection.is_active():
		await SimusNetEvents.event_connected.published
	
	if !get_identity().is_ready:
		await get_identity().on_ready
	
	_network_ready()

func _tick(delta: float) -> void:
	for config in _properties_for:
		if config._tickrate <= 0:
			config._process_sync(self)
			continue
		
		var cfg_id: int = _properties_for.keys().find(config)
		var time: float = _properties_time.get_or_add(cfg_id, 0.0)
		time = move_toward(time, 1.0 / config._tickrate, delta)
		_properties_time.set(cfg_id, time)
		if time >= 1.0 / config._tickrate:
			config._process_sync(self)
			_properties_time.set(cfg_id, 0.0)
		

func _network_ready() -> void:
	for cfg in _properties_for:
		cfg._network_ready(self)

func _network_disconnect() -> void:
	for cfg in _properties_for:
		cfg._network_disconnect(self)

func _deinitialize_dynamic() -> void:
	_network_disconnect()
	_initialize_dynamic()

static func find_in(object: Object) -> SimusNetVarConfigHandler:
	if object.has_meta(_META):
		var cfg: SimusNetVarConfigHandler = object.get_meta(_META)
		if is_instance_valid(cfg):
			if cfg.get_object() == object:
				return cfg
	return null

static func get_or_create(object: Object) -> SimusNetVarConfigHandler:
	var founded: SimusNetVarConfigHandler = find_in(object)
	if founded:
		return founded
	
	var new: SimusNetVarConfigHandler = SimusNetVarConfigHandler.new()
	new._object_weak_ref = weakref(object)
	new._identity_weak_ref = weakref(SimusNetIdentity.register(object))
	object.set_meta(_META, new)
	new._initialize()
	return new
