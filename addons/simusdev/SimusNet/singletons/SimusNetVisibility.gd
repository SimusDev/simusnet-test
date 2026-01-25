extends SimusNetSingletonChild
class_name SimusNetVisibility

static var _queue_create: Array[SimusNetIdentity] = []
static var _queue_delete: Array[SimusNetIdentity] = []

static var _instance: SimusNetVisibility

func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_DISABLED
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)

func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if !_queue_create.is_empty():
		_handle(_queue_create, true)
		_queue_create.clear()
	
	if !_queue_delete.is_empty():
		_handle(_queue_delete, false)
		_queue_delete.clear()

func _handle(array: Array[SimusNetIdentity], creation: bool) -> void:
	var parsed_identities: PackedByteArray = _parse_identities(array)
	
	_server_receive_identities.rpc_id(SimusNet.SERVER_ID, parsed_identities, creation)
	
	SimusNetProfiler._instance._visibility_sent += array.size()
	SimusNetProfiler._put_up_packet()
	SimusNetProfiler._instance._put_visibility_up_traffic(parsed_identities.size() + 4)

func _parse_identities(array: Array[SimusNetIdentity]) -> PackedByteArray:
	var result: Array = []
	for i in array:
		if is_instance_valid(i.owner):
			result.append(i.get_unique_id())
	return SimusNetCompressor.parse(result)

func _parse_identities_from_packet(packet: PackedByteArray) -> Array[SimusNetIdentity]:
	var result: Array[SimusNetIdentity] = []
	var array: Array = SimusNetDecompressor.parse(packet)
	for i in array:
		var id: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(i)
		if id:
			result.append(id)
	return result

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VISIBILITY)
func _server_receive_identities(packet: PackedByteArray, creation: bool = true) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var sender: int = multiplayer.get_remote_sender_id()
	
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_visibility_down_traffic(packet.size() + 4)
	
	var identities: Array[SimusNetIdentity] = _parse_identities_from_packet(packet)
	
	var non_server_identities: Dictionary[int, Array] = {}
	
	for identity in identities:
		SimusNetProfiler._instance._visibility_received += 1
		
		var authority: int = SimusNet.get_network_authority(identity.owner)
		
		set_visible_for(sender, identity.owner, creation)
		
		if authority != SimusNet.SERVER_ID and authority != sender:
			var ids: Array[SimusNetIdentity] = non_server_identities.get_or_add(authority, [] as Array[SimusNetIdentity])
			ids.append(identity)
	
	if non_server_identities.is_empty():
		return
	
	for pid: int in non_server_identities:
		var ids: Array[SimusNetIdentity] = non_server_identities[pid]
		var bytes: PackedByteArray = _parse_identities(ids)
		
		SimusNetProfiler._put_up_packet()
		SimusNetProfiler._instance._put_visibility_up_traffic(bytes.size())
		SimusNetProfiler._instance._visibility_sent += ids.size()
		
		_client_receive_identities_from.rpc_id(pid, sender, bytes, creation)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VISIBILITY)
func _client_receive_identities_from(peer: int, packet: PackedByteArray, creation: bool = true) -> void:
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_visibility_down_traffic(packet.size() + 8)
	
	var identities: Array[SimusNetIdentity] = _parse_identities_from_packet(packet)
	for identity in identities:
		SimusNetProfiler._instance._visibility_received += 1
		set_visible_for(peer, identity.owner, creation)
		
	

static func _local_identity_create(identity: SimusNetIdentity) -> void:
	if !singleton.settings.visibility_auto_handling or SimusNetConnection.is_server():
		return
	
	SimusNetVisibility.set_public_visibility(identity.owner, false)
	_queue_create.append(identity)

static func _local_identity_delete(identity: SimusNetIdentity) -> void:
	if !singleton.settings.visibility_auto_handling or SimusNetConnection.is_server():
		return
	
	_queue_delete.append(identity)

static func _serialize_array(array: Array[SimusNetIdentity]) -> void:
	pass

static func _deserialize_array(array: Array[PackedByteArray]) -> void:
	pass

static func set_public_visibility(object: Object, visibility: bool) -> SimusNetVisibility:
	SimusNetVisible.get_or_create(object).set_public_visibility(visibility)
	return _instance

static func set_visible_for(peer: int, object: Object, visible: bool) -> SimusNetVisibility:
	SimusNetVisible.get_or_create(object).set_visible_for(peer, visible)
	return _instance

static func is_public_visible(object: Object) -> bool:
	return SimusNetVisible.get_or_create(object).is_public_visible()

static func get_peers_from(object: Object) -> PackedInt32Array:
	return SimusNetVisible.get_or_create(object).get_peers()

static func is_visible_for(peer: int, object: Object) -> bool:
	return SimusNetVisible.get_or_create(object).is_visible_for(peer)

static func is_method_always_visible(callable: Callable) -> bool:
	return SimusNetVisible.get_or_create(callable.get_object()).is_method_always_visible(callable)

static func set_method_always_visible(callables: Array[Callable], visibility: bool = true) -> SimusNetVisibility:
	for i in callables:
		SimusNetVisible.get_or_create(i.get_object()).set_method_always_visible([i], visibility)
	return _instance
