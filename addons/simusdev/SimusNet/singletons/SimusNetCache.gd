extends SimusNetSingletonChild
class_name SimusNetCache

static var instance: SimusNetCache

var _data: Dictionary[String, Variant] = {} 

static func get_data() -> Dictionary[String, Variant]:
	return instance._data

static func _set_data(new: Dictionary[String, Variant]) -> void:
	instance._data = new

static func data_get_or_add(key: String, default: Variant = null) -> Variant:
	var dict: Dictionary[String, Variant] = get_data()
	if dict.has(key):
		return dict.get(key)
	
	dict.set(key, default)
	return default
	

static func clear() -> void:
	get_data().clear()

func initialize() -> void:
	instance = self
	process_mode = Node.NOTIFICATION_DISABLED
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)

func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

var _unique_id_queue: Array = []

signal on_unique_id_received(generated_id: Variant, unique_id: Variant)

static func request_unique_id(id: Variant) -> void:
	if !instance._unique_id_queue.has(id):
		instance._unique_id_queue.append(id)
	

func _process(delta: float) -> void:
	if _unique_id_queue.is_empty() or SimusNetConnection.is_server():
		return
	
	_unique_id_request_rpc.rpc_id(SimusNet.SERVER_ID, SimusNetCompressor.parse(_unique_id_queue))
	_unique_id_queue.clear()

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.IDENTITY)
func _unique_id_request_rpc(serialized: Variant) -> void:
	if not SimusNetConnection.is_server():
		return
	
	var packet: Dictionary = {}
	var id_list: Array = SimusNetDecompressor.parse(serialized)
	
	for id: Variant in id_list:
		var identity: SimusNetIdentity = SimusNetIdentity._list_by_generated_id.get(id)
		if identity:
			packet[id] = identity.get_unique_id()
	
	if !packet.is_empty():
		_unique_id_request_receive.rpc_id(multiplayer.get_remote_sender_id(), SimusNetCompressor.parse(packet))

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.IDENTITY)
func _unique_id_request_receive(serialized: Variant) -> void:
	if SimusNetConnection.is_server():
		return
	
	var dict: Dictionary = SimusNetDecompressor.parse(serialized)
	for generated_id: Variant in dict:
		var unique_id: Variant = dict[generated_id]
		on_unique_id_received.emit(generated_id, unique_id)


static func _cache_identity(identity: SimusNetIdentity) -> void:
	return
	
	if SimusNetConnection.is_server():
		instance._cache_identity_rpc.rpc(identity.get_generated_unique_id(), identity.get_unique_id())

@rpc("authority", "call_local", "reliable", SimusNetChannels.BUILTIN.IDENTITY)
func _cache_identity_rpc(generated_id: Variant, unique_id: int) -> void:
	SimusNetIdentity.get_cached_unique_ids_values().set(generated_id, unique_id)
	SimusNetIdentity.get_cached_unique_ids().set(unique_id, generated_id)
	SimusNetEvents.event_identity_cached.generated_unique_id = generated_id
	SimusNetEvents.event_identity_cached.unique_id = unique_id
	SimusNetEvents.event_identity_cached.publish()

static func _uncache_identity(identity: SimusNetIdentity) -> void:
	return
	
	if SimusNetConnection.is_server():
		identity.get_cached_unique_ids().erase(identity.get_unique_id())
		identity.get_cached_unique_ids_values().erase(identity.get_generated_unique_id())
