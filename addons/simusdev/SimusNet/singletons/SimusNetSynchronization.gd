extends SimusNetSingletonChild
class_name SimusNetSynchronization

static var _instance: SimusNetSynchronization

var _transforms: Array[SimusNetTransform] = []

const TRANSFORM_META: StringName = &"NetworkTransform"

func _init() -> void:
	_instance = self

static func get_synced_properties(object: Object) -> Dictionary[StringName, Variant]:
	return SD_Variables.get_or_add_object_meta(object, &"SimusNetPSynced", {} as Dictionary[StringName, Variant])

static func get_changed_properties(object: Object) -> Dictionary[StringName, Variant]:
	return SD_Variables.get_or_add_object_meta(object, &"SimusNetPChanges", {} as Dictionary[StringName, Variant])

static func get_transforms() -> Array[SimusNetTransform]:
	return _instance._transforms

func initialize() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_instance = self
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)
	


func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

var _transforms_that_ready: Array[SimusNetTransform] = []

func _transform_tick(transform: SimusNetTransform) -> void:
	if !_transforms_that_ready.has(transform):
		_transforms_that_ready.append(transform)

var _transform_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
var _transform_packets: Dictionary[int, Dictionary] = {}

func _process(delta: float) -> void:
	var size: int = 0
	var batch_id: int = 0
	
	for transform in _transforms_that_ready:
		if !is_instance_valid(transform):
			continue
		
		var transform_data: Dictionary = {}
		
		if transform._hook_position_snapshot():
			transform_data.set(0, transform.node.position)
		
		if transform._hook_rotation_snapshot():
			transform_data.set(1, transform.node.rotation)
		
		if transform._hook_scale_snapshot():
			_transform_buffer.clear()
			transform_data.set(2, transform.node.scale)
		
		if size >= singleton.settings.synchronization_transform_batch_count:
			batch_id += 1
			size = 0
		
		size += 1
		
		if transform_data.is_empty():
			continue
		
		for p_id: int in SimusNetConnection.get_connected_peers():
			if SimusNetVisibility.is_visible_for(p_id, transform):
				var peer_data: Dictionary = _transform_packets.get_or_add(p_id, {})
				var batch_data: Dictionary = peer_data.get_or_add(batch_id, {})
				
				batch_data.set(transform._identity.get_unique_id(), transform_data)
				
	
	_transforms_that_ready.clear()
	
	if _transform_packets.is_empty():
		return
	
	for peer: int in _transform_packets:
		var peer_data: Dictionary = _transform_packets[peer]
		for _batch: int in peer_data:
			var batch_data: Dictionary = peer_data[_batch]
			var reliable: bool = false
			
			var bytes: PackedByteArray = SimusNetDictionarySerializer.serialize(batch_data)
			if reliable:
				_receive_batched_transform_rpc_reliable.rpc_id(peer, bytes)
			else:
				_receive_batched_transform_rpc.rpc_id(peer, bytes)
			
			SimusNetProfiler.get_instance()._transform_up_traffic += bytes.size() + 3
			SimusNetProfiler.get_instance()._total_traffic += bytes.size() + 3
			SimusNetProfiler.get_instance()._up_traffic += bytes.size() + 3
			SimusNetProfiler.get_instance()._put_up_packet()
			
	
	_transform_packets.clear()

@rpc("any_peer", "call_remote", "unreliable", SimusNetChannels.BUILTIN.TRANSFORM)
func _receive_batched_transform_rpc(packet: PackedByteArray) -> void:
	_receive_batched_transform(packet)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.TRANSFORM_RELIABLE)
func _receive_batched_transform_rpc_reliable(packet: PackedByteArray) -> void:
	_receive_batched_transform(packet)

func _receive_batched_transform(packet: PackedByteArray) -> void:
	var bytes_size: int = packet.size() + 3
	
	SimusNetProfiler.get_instance()._put_down_packet()
	SimusNetProfiler.get_instance()._transform_down_traffic += bytes_size
	SimusNetProfiler.get_instance()._total_traffic += bytes_size
	SimusNetProfiler.get_instance()._down_traffic += bytes_size
	
	var deserialized: Dictionary = SimusNetDictionarySerializer.deserialize(packet)
	for identity_id: int in deserialized:
		var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(identity_id)
		if !identity:
			logger.debug_error("_receive_batched_transform() from peer %s, failed to find SimusNetTransform with ID %s on your local instance." % [multiplayer.get_remote_sender_id(), identity_id])
			continue
		
		if !identity.owner:
			logger.debug_error("_receive_batched_transform() from peer %s, failed to find SimusNetTransform with ID %s on your local instance." % [multiplayer.get_remote_sender_id(), identity_id])
			continue
		
		if SimusNet.get_network_authority(identity.owner) == multiplayer.get_remote_sender_id() or multiplayer.get_remote_sender_id() == SimusNet.SERVER_ID:
			var data: Dictionary = deserialized[identity_id]
			var transform: SimusNetTransform = identity.owner
			
			var position: Variant = data.get(0, transform.node.position)
			var rotation: Variant = data.get(1, transform.node.rotation)
			var scale: Variant = data.get(2, transform.node.scale)
			
			transform._data.set(SimusNetTransform._PP, position)
			transform._data.set(SimusNetTransform._RP, rotation)
			transform._data.set(SimusNetTransform._SP, scale)
			
			if !transform.interpolate:
				transform.node.position = position
				transform.node.rotation = rotation
				transform.node.scale = scale
				
		
func _transform_ready(transform: SimusNetTransform) -> void:
	pass

func _transform_enter_tree(transform: SimusNetTransform) -> void:
	if _transforms.has(transform):
		return
	
	_transforms.append(transform)

func _transform_exit_tree(transform: SimusNetTransform) -> void:
	_transforms.erase(transform)
