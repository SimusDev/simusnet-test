extends RefCounted
class_name SimusNetRPCConfigHandler

var _list: Dictionary[Callable, SimusNetRPCConfig] = {}
var _list_by_unique_id: Dictionary[int, SimusNetRPCConfig] = {}
var _list_by_name: Dictionary[String, SimusNetRPCConfig] = {}

var object: Object : get = get_object

const META: StringName = "SimusNetRPCConfigHandler"

func get_object() -> Object:
	if !is_instance_valid(object):
		object = null
	return null

static func get_or_create(object: Object) -> SimusNetRPCConfigHandler:
	if object.has_meta("SimusNetRPCConfigHandler"):
		var cfg: SimusNetRPCConfigHandler = object.get_meta(META)
		if is_instance_valid(cfg):
			if cfg.object == object:
				return cfg
	
	var handler := SimusNetRPCConfigHandler.new()
	handler.object = object
	object.set_meta(META, handler)
	return handler
