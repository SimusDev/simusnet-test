@static_unload
extends RefCounted
class_name SimusNet

const SERVER_ID: int = 1

static func is_network_authority(object: Object) -> bool:
	var authority: int = get_network_authority(object) 
	if SimusNetConnection.is_server():
		if authority != SERVER_ID and !SimusNetConnection.get_connected_peers().has(authority):
			return true
	return authority == SimusNetConnection.get_unique_id()

static func get_network_authority(object: Object) -> int:
	if is_instance_valid(object):
		if object.has_method("get_multiplayer_authority"):
			return object.get_multiplayer_authority()
	return SimusNetConnection.SERVER_ID
