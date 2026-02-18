@abstract
extends RefCounted
class_name SimusNetSyncedType

var config: SimusNetSyncedTypeConfig
var owner: Object : get = get_owner

var network_id: int = -1

func get_owner() -> Object:
	if !is_instance_valid(owner):
		owner = null
	return owner

func _init(owner: Node, config: SimusNetSyncedTypeConfig = SimusNetSyncedTypeConfig.new()) -> void:
	if owner is Node:
		if !owner.is_node_ready():
			await owner.ready
	
	self.config = config
	self.owner = owner
	
	var handler: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.get_or_create(owner)
	handler._list.append(self)
	network_id = handler._list.size() - 1

func _tick(handler: SimusNetSyncedTypeHandler, delta: float) -> void:
	pass

func _network_ready(handler: SimusNetSyncedTypeHandler) -> void:
	pass

func _network_disconnect(handler: SimusNetSyncedTypeHandler) -> void:
	pass

func start_replicate_serialize() -> Variant:
	return null

func start_replicate_deserialize() -> Variant:
	return null

func send_serialize() -> Variant:
	return null

func receive_deserialize() -> Variant:
	return null

func is_ready_to_send() -> bool:
	return false
