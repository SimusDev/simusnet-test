@abstract
extends RefCounted
class_name SimusNetSyncedType

var config: SimusNetSyncedTypeConfig
var owner: Object : get = get_owner
var identity: SimusNetIdentity

var network_id: int = -1

var is_ready: bool = false

signal on_ready()

signal _on_value_changed()

var ___changes: Array = []

func hook_on_value_changed(callable: Callable, emit_at_connect: bool = true) -> SimusNetSyncedType:
	if _on_value_changed.is_connected(callable):
		return self
	
	_on_value_changed.connect(callable)
	if emit_at_connect:
		callable.call()
	return self

func get_owner() -> Object:
	if !is_instance_valid(owner):
		owner = null
	return owner

func _init(_owner: Node, _config: SimusNetSyncedTypeConfig = SimusNetSyncedTypeConfig.new()) -> void:
	_initialize_async(_owner, _config)

func _initialize_async(_owner: Object, _config: SimusNetSyncedTypeConfig) -> void:
	if owner is Node:
		if !owner.is_node_ready():
			await owner.ready
	
	config = _config
	owner = _owner
	identity = SimusNetIdentity.register(owner)
	
	var handler: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.get_or_create(owner)
	handler._list.append(self)
	network_id = handler._list.size() - 1
	
	_initialized()
	
	if !self.identity.is_ready:
		await self.identity.on_ready
	
	is_ready = true
	on_ready.emit()

func _initialized() -> void:
	pass

func _tick(handler: SimusNetSyncedTypeHandler, delta: float) -> void:
	pass

func _network_ready(handler: SimusNetSyncedTypeHandler) -> void:
	SimusNetVars.get_instance()._replicate_synced_type(self)

func _network_disconnect(handler: SimusNetSyncedTypeHandler) -> void:
	pass

func _start_replicate_serialize() -> Variant:
	return null

func _start_replicate_deserialize(data: Variant) -> Variant:
	return null

func _on_replication_received(data: Variant) -> void:
	pass

func _on_changes_received(changes: Array) -> void:
	pass

func _on_changes_received_authority(changes: Array) -> void:
	pass

func _validate_send(to_peer: int) -> bool:
	if config._mode == SimusNetSyncedTypeConfig.MODE.TO_SERVER:
		return to_peer == SimusNet.SERVER_ID
	return true

func _validate_receive(from_peer: int) -> bool:
	if config._mode == SimusNetSyncedTypeConfig.MODE.AUTHORITY:
		return SimusNet.get_network_authority(owner) == from_peer
	
	if config._mode == SimusNetSyncedTypeConfig.MODE.SERVER_ONLY:
		return from_peer == SimusNet.SERVER_ID
	
	if config._mode == SimusNetSyncedTypeConfig.MODE.TO_SERVER:
		return SimusNetConnection.is_server()
	
	return true

func _network_update() -> SimusNetSyncedType:
	if ___changes.is_empty():
		return
	
	if !_is_network_authority():
		return
	
	if !is_ready:
		await on_ready
	
	_network_update_begin()
	SimusNetVars.get_instance()._update_send_synced_type(self)
	_on_changes_received_authority(___changes)
	___changes.clear()
	return self

func _network_update_begin() -> void:
	pass

func _put_change(value: Variant) -> void:
	if !_is_network_authority():
		return
	
	___changes.append(value)
	_network_update()

func _is_network_authority() -> bool:
	if config._mode == SimusNetSyncedTypeConfig.MODE.AUTHORITY:
		return SimusNet.is_network_authority(owner)
	
	if config._mode == SimusNetSyncedTypeConfig.MODE.SERVER_ONLY:
		return SimusNetConnection.is_server()
	
	if config._mode == SimusNetSyncedTypeConfig.MODE.TO_SERVER:
		if !SimusNetConnection.is_server():
			return SimusNet.is_network_authority(owner)
	
	return false
