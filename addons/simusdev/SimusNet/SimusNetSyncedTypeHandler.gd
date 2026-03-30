extends RefCounted
class_name SimusNetSyncedTypeHandler

const _META: StringName = &"NetSyncedTypesHandler"

var _object: Object : get = get_object
var _identity: SimusNetIdentity

var _list: Array[SimusNetSyncedType] = []

func get_object() -> Object:
	if !is_instance_valid(_object):
		_object = null
	return _object

func get_synced_type_by_id(id: int) -> SimusNetSyncedType:
	return _list.get(id)

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
	for type in _list:
		type._tick(self, delta)

func _network_ready() -> void:
	for type in _list:
		type._network_ready(self)

func _network_disconnect() -> void:
	for type in _list:
		type._network_disconnect(self)

func _deinitialize_dynamic() -> void:
	_network_disconnect()
	_initialize_dynamic()

static func find_in(object: Object) -> SimusNetSyncedTypeHandler:
	if object.has_meta(_META):
		var cfg: SimusNetSyncedTypeHandler = object.get_meta(_META)
		if is_instance_valid(cfg):
			if cfg.get_object() == object:
				return cfg
	return null

static func get_or_create(object: Object) -> SimusNetSyncedTypeHandler:
	var founded: SimusNetSyncedTypeHandler = find_in(object)
	if founded:
		return founded
	
	var new: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.new()
	new._object = object
	object.set_meta(_META, new)
	new._identity = SimusNetIdentity.register(object)
	new._initialize()
	return new
