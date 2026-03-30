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
	_queue_create.clear()
	_queue_delete.clear()
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if !_queue_delete.is_empty():
		_handle(_queue_delete, false)
		_queue_delete.clear()
	
	if !_queue_create.is_empty():
		_handle(_queue_create, true)
		_queue_create.clear()
	

func _handle(array: Array[SimusNetIdentity], creation: bool) -> void:
	var parsed_identities: Variant = _parse_identities(array)
	
	_server_receive_identities.rpc_id(SimusNet.SERVER_ID, parsed_identities, creation)
	
	SimusNetProfiler._instance._visibility_sent += array.size()
	SimusNetProfiler._put_up_packet()
	SimusNetProfiler._instance._put_visibility_up_traffic(parsed_identities.size() + 4)

func _parse_identities(array: Array[SimusNetIdentity]) -> Variant:
	var result: Array = []
	for i in array:
		result.append(i.get_unique_id())
	return SimusNetCompressor.parse_if_necessary(result)

func _parse_identities_from_packet(packet: Variant) -> Array[SimusNetIdentity]:
	var result: Array[SimusNetIdentity] = []
	var array: Array = SimusNetDecompressor.parse_if_necessary(packet)
	for i in array:
		var id: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(i)
		if is_instance_valid(id) and is_instance_valid(id.owner):
			result.append(id)
	return result

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VISIBILITY)
func _server_receive_identities(packet: Variant, creation: bool = true) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var sender: int = multiplayer.get_remote_sender_id()
	
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_visibility_down_traffic(packet.size() + 4)
	
	var identities: Array[SimusNetIdentity] = _parse_identities_from_packet(packet)
	
	var peers_and_identities_for_sender: Dictionary[Variant, PackedInt32Array] = {}
	
	SimusNetProfiler._instance._visibility_received += identities.size()
	
	var _peers_and_identities: Dictionary[int, Array] = {}
	
	for identity in identities:
		var authority: int = SimusNet.get_network_authority(identity.owner)
		var visibile: SimusNetVisible = SimusNetVisible.get_or_create(identity.owner)
		
		visibile.set_visible_for(sender, creation)
		
		if not visibile.is_server_only():
			if authority != SimusNet.SERVER_ID:
				if sender != authority:
					var ids: Array = _peers_and_identities.get_or_add(authority, [])
					ids.append(identity.get_unique_id())
	
	if _peers_and_identities.is_empty():
		return
	
	var sender_bytes: Variant = SimusNetCompressor.parse_if_necessary(_peers_and_identities)
	_client_receive_identities_sender.rpc_id(sender, sender_bytes, creation)
	
	SimusNetProfiler._put_up_packet()
	SimusNetProfiler._instance._put_visibility_up_traffic(sender_bytes.size())
	SimusNetProfiler._instance._visibility_sent += _peers_and_identities.size()
	
	for pid: int in _peers_and_identities:
		var owner_bytes: Variant = SimusNetCompressor.parse_if_necessary(_peers_and_identities[pid])
		_client_receive_identities_owner.rpc_id(pid, sender, owner_bytes, creation)
		SimusNetProfiler._put_up_packet()
		SimusNetProfiler._instance._put_visibility_up_traffic(sender_bytes.size())
		SimusNetProfiler._instance._visibility_sent += _peers_and_identities[pid].size()

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.VISIBILITY)
func _client_receive_identities_sender(bytes: Variant, creation: bool) -> void:
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_visibility_down_traffic(bytes.size())
	
	var _peers_and_identities: Dictionary[int, Array] = SimusNetDecompressor.parse_if_necessary(bytes)
	for pid: int in _peers_and_identities:
		var ids: Array = _peers_and_identities[pid]
		SimusNetProfiler._instance._visibility_received += ids.size()
		for s_id in ids:
			var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(s_id)
			#print("sender receive: ", s_id, ", ", identity)
			
			if is_instance_valid(identity) and identity.owner:
				set_visible_for(pid, identity.owner, creation)
			

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.VISIBILITY)
func _client_receive_identities_owner(peer: int, bytes: Variant, creation: bool) -> void:
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_visibility_down_traffic(bytes.size())
	
	var ids: Array = SimusNetDecompressor.parse_if_necessary(bytes)
	SimusNetProfiler._instance._visibility_received += ids.size()
	for s_id in ids:
		_owner_recursive_receive(peer, s_id, creation, 360)

func _owner_recursive_receive(peer: int, identity_id: Variant, creation: bool, attempts: int) -> void:
	if attempts <= 0:
		logger.push_error("_owner_recursive_receive(): failed to receive %s from %s" % [identity_id, peer])
		return
	
	var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(identity_id)
	#print("owner receive: ", identity_id, ", ", identity)
	
	if is_instance_valid(identity) and identity.owner:
		set_visible_for(peer, identity.owner, creation)
		return
	
	await get_tree().physics_frame
	_owner_recursive_receive(peer, identity_id, creation, attempts - 1)
	

static func _local_identity_create(identity: SimusNetIdentity) -> void:
	if singleton.settings.visibility_auto_handling:
		SimusNetVisibility.set_public_visibility(identity.owner, false)
	
	if SimusNetConnection.is_server():
		return
	
	_queue_create.append(identity)

static func _local_identity_delete(identity: SimusNetIdentity) -> void:
	if SimusNetConnection.is_server():
		return
	
	_queue_delete.append(identity)

static func _serialize_array(array: Array[SimusNetIdentity]) -> void:
	pass

static func _deserialize_array(array: Array[Variant]) -> void:
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
