extends RefCounted
class_name SimusNetVarConfigHandler

const _META: StringName = &"simusnet_var_config"

var _object: Object
var _identity: SimusNetIdentity

var _list: Dictionary[StringName, SimusNetVarConfig] = {}
var _properties_for: Dictionary[SimusNetVarConfig, PackedStringArray]

func get_properties_for(cfg: SimusNetVarConfig) -> PackedStringArray:
	return _properties_for.get(cfg, PackedStringArray())

func get_object() -> Object:
	if !is_instance_valid(_object):
		_object = null
	return _object

func get_identity() -> SimusNetIdentity:
	return _identity

func _add_cfg(cfg: SimusNetVarConfig, property: StringName) -> void:
	_list[property] = cfg
	
	var properties: PackedStringArray = _properties_for.get_or_add(cfg, PackedStringArray())
	if !property in properties:
		properties.append(property)
	
	if SimusNetConnection.is_active():
		cfg._network_ready(self)

func _initialize() -> void:
	SimusNetVars.get_instance().on_tick.connect(_tick)
	SimusNetEvents.event_disconnected.listen(_deinitialize_dynamic)
	_initialize_dynamic()

func _initialize_dynamic() -> void:
	if !SimusNetConnection.is_active():
		await SimusNetEvents.event_connected.published
	
	if !_identity.is_ready:
		await _identity.on_ready
	
	_network_ready()

func _tick(delta: float) -> void:
	for config in _properties_for:
		config._on_tick(self, delta)

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
		var cfg: Variant = object.get_meta(_META)
		if is_instance_valid(cfg):
			return cfg
	return null

static func get_or_create(object: Object) -> SimusNetVarConfigHandler:
	var founded: SimusNetVarConfigHandler = find_in(object)
	if founded:
		return founded
	
	var new: SimusNetVarConfigHandler = SimusNetVarConfigHandler.new()
	new._object = object
	object.set_meta(_META, new)
	new._identity = SimusNetIdentity.register(object)
	new._initialize()
	return new
