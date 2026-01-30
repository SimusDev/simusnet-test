@static_unload
extends RefCounted
class_name SimusNet

const SERVER_ID: int = 1

static func is_network_authority(object: Object) -> bool:
	return get_network_authority(object)  == SimusNetConnection.get_unique_id()

static func get_network_authority(object: Object) -> int:
	if is_instance_valid(object):
		if object.has_method("get_multiplayer_authority"):
			var peer: int = object.get_multiplayer_authority()
			if SimusNetConnection.get_connected_peers_include_self().has(peer):
				return peer
	return SimusNetConnection.SERVER_ID
