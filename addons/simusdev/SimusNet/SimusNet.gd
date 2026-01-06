@static_unload
extends RefCounted
class_name SimusNet

const SERVER_ID: int = 1

static func is_network_authority(object: Object) -> bool:
	return get_network_authority(object) == SimusNetConnection.get_unique_id()

static func get_network_authority(object: Object) -> int:
	if object.has_method("get_multiplayer_authority"):
		return object.get_multiplayer_authority()
	return SimusNetConnection.SERVER_ID
