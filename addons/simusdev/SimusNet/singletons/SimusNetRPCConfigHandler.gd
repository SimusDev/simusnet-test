extends RefCounted
class_name SimusNetRPCConfigHandler

var _list: Dictionary[Callable, SimusNetRPCConfig] = {}
var _list_by_unique_id: Dictionary[int, SimusNetRPCConfig] = {}
var _list_by_name: Dictionary[String, SimusNetRPCConfig] = {}

var _object: Object : get = get_object

const META: StringName = "SimusNetRPCConfigHandler"

func get_object() -> Object:
	if !is_instance_valid(_object):
		_object = null
	return _object

static func get_or_create(object: Object) -> SimusNetRPCConfigHandler:
	if object.has_meta(META):
		var cfg: SimusNetRPCConfigHandler = object.get_meta(META)
		if is_instance_valid(cfg):
			if cfg.get_object():
				if cfg.get_object() == object:
					return cfg
	
	var handler := SimusNetRPCConfigHandler.new()
	handler._object = object 
	object.set_meta(META, handler)
	return handler
