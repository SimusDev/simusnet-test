extends RefCounted
class_name SimusNetRPCConfigHandler

var _list_by_name: Dictionary[StringName, SimusNetRPCConfig] = {}
var _list_by_unique_id: Dictionary[int, SimusNetRPCConfig] = {}

var _callables: Dictionary[StringName, Callable] = {}

var _object: Object : get = get_object

var _object_weak_ref: WeakRef

const META: StringName = "SimusNetRPCConfigHandler"

signal _async_received()
var _async_method: StringName
var _async_args: Array = []

func get_method_unique_id(method: StringName) -> int:
	return _list_by_name.keys().find(method)

func get_method_name_by_unique_id(id: int) -> StringName:
	return _list_by_name.keys().get(id)

func get_callable_by_method_name(name: StringName) -> Variant:
	return _callables.get(name, null)

func get_object() -> Object:
	if _object_weak_ref:
		return _object_weak_ref.get_ref()
	return null

static func get_or_create(object: Object) -> SimusNetRPCConfigHandler:
	if object.has_meta(META):
		var cfg: SimusNetRPCConfigHandler = object.get_meta(META)
		if is_instance_valid(cfg):
			if cfg.get_object():
				if cfg.get_object() == object:
					return cfg
	
	var handler := SimusNetRPCConfigHandler.new()
	handler._object_weak_ref = weakref(object) 
	object.set_meta(META, handler)
	handler._initialize()
	return handler

func _initialize() -> void:
	SimusNetConnection.connect_network_node_callables(
		self,
		_network_ready,
		_network_disconnect,
		_network_not_connected
	)

func _network_ready() -> void:
	for c_name in _list_by_name:
		#SimusNetMethods.cache_by_name(c_name)
		_list_by_name[c_name]._network_ready(self)

func _network_disconnect() -> void:
	for c_name in _list_by_name:
		_list_by_name[c_name]._network_disconnect(self)

func _network_not_connected() -> void:
	pass
