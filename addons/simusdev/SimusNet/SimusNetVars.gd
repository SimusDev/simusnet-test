extends SimusNetSingletonChild
class_name SimusNetVars

const BUILTIN_CACHE: PackedStringArray = [
	"transform",
	"position",
	"rotation",
	"scale",
]

static var _instance: SimusNetVars

static var _event_cached: SimusNetEventVariableCached
static var _event_uncached: SimusNetEventVariableUncached

var _timer: Timer

static func get_cached() -> PackedStringArray:
	return SimusNetCache.data_get_or_add("v", PackedStringArray())

static func get_id(property: String) -> int:
	return get_cached().find(property)

static func get_name_by_id(id: int) -> String:
	return get_cached().get(id)

static func try_serialize_into_variant(property: String) -> Variant:
	var method_id: int = get_id(property)
	if method_id > -1:
		return method_id
	return property

static func try_deserialize_from_variant(variant: Variant) -> String:
	if variant is int:
		return get_cached().get(variant)
	return variant as String

static func try_serialize_array_into_variant(properties: PackedStringArray) -> Variant:
	var result: Array = []
	for p in properties:
		result.append(try_serialize_into_variant(p))
	return result

static func try_deserialize_array_from_variant(variant: Variant) -> PackedStringArray:
	var result: PackedStringArray = []
	for p in variant:
		result.append(try_deserialize_from_variant(p))
	return result
	

func initialize() -> void:
	_instance = self
	_event_cached = SimusNetEvents.event_variable_cached
	_event_uncached = SimusNetEvents.event_variable_uncached
	
	SimusNetEvents.event_connected.listen(_on_connected)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)
	
	for p in BUILTIN_CACHE:
		cache(p)
	
	process_mode = Node.PROCESS_MODE_DISABLED
	
	_timer = Timer.new()
	_timer.timeout.connect(_on_tick)
	_timer.wait_time = 1.0 / singleton.settings.synchronization_vars_tickrate
	add_child(_timer)
	
	



func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_timer.start()
	
func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_timer.stop()

var _queue_replicate: Dictionary = {}
var _queue_replicate_unreliable: Dictionary = {}

var _queue_replicate_server: Dictionary = {}

var _queue_send: Dictionary = {}

func _on_tick() -> void:
	_timer.wait_time = 1.0 / singleton.settings.synchronization_vars_tickrate
	
	if !_queue_replicate.is_empty():
		_handle_replicate(_queue_replicate, true)
		_queue_replicate.clear()
	
	if !_queue_replicate_unreliable.is_empty():
		_handle_replicate(_queue_replicate_unreliable, false)
		_queue_replicate_unreliable.clear()
	
	if !_queue_replicate_server.is_empty():
		_handle_replicate_server(_queue_replicate_server)
		_queue_replicate_server.clear()
	

static func replicate(object: Object, properties: PackedStringArray, reliable: bool = true) -> void:
	var identity: SimusNetIdentity = SimusNetIdentity.register(object)
	
	if SimusNetConnection.is_server():
		for p in properties:
			cache(p)
		return
		
	if !identity.is_ready:
		await identity.on_ready
	
	
	var packet: Dictionary = _instance._queue_replicate_unreliable
	if reliable:
		packet = _instance._queue_replicate
	
	var data_properties: Array = packet.get_or_add(identity.try_serialize_into_variant(), [])
	for i in try_serialize_array_into_variant(properties):
		if !data_properties.has(i):
			data_properties.append(i)
	

func _handle_replicate(data: Dictionary, reliable: bool) -> void:
	var compressed: Variant = SimusNetCompressor.parse(data)
	if reliable:
		_replicate_rpc.rpc_id(SimusNet.SERVER_ID, compressed)
	else:
		_replicate_rpc_unreliable.rpc_id(SimusNet.SERVER_ID, compressed)

func _replicate_rpc_server(packet: Variant, peer: int, reliable: bool) -> void:
	var data: Dictionary = SimusNetDecompressor.parse(packet)
	
	for identity_id in data:
		var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(identity_id)
		if !identity:
			continue
		
		var peer_data: Dictionary = _queue_replicate_server.get_or_add(peer, {})
		
		var properties: PackedStringArray = try_deserialize_array_from_variant(data[identity_id])
		
		var reliable_data: Dictionary = peer_data.get_or_add(reliable, {})
		var identity_data: Dictionary = reliable_data.get_or_add(identity_id, {})
		
		for p_name: String in properties:
			cache(p_name)
			if p_name in identity.owner:
				identity_data.set(try_serialize_into_variant(p_name), SimusNetSerializer.parse(identity.owner.get(p_name)))
		
	
	

func _handle_replicate_server(data: Dictionary) -> void:
	for peer: int in data:
		var packet: Dictionary = {}
		var packet_unreliable: Dictionary = {}
		
		var peer_data: Dictionary = data[peer]
		for reliable: bool in peer_data:
			if reliable:
				packet.merge(peer_data[reliable])
			else:
				packet_unreliable.merge(peer_data[reliable])
		
			if !packet.is_empty():
				_replicate_client_recieve.rpc_id(peer, SimusNetCompressor.parse(packet))
			
			if !packet_unreliable.is_empty():
				_replicate_client_recieve_unreliable.rpc_id(peer, SimusNetCompressor.parse(packet_unreliable))

func _replicate_client(packet: Variant) -> void:
	var data: Dictionary = SimusNetDecompressor.parse(packet)
	for identity_id in data:
		var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(identity_id)
		if identity:
			for s_p in data[identity_id]:
				var property: String = try_deserialize_from_variant(s_p)
				var value: Variant = data[identity_id][s_p]
				identity.owner.set(property, value)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS_RELIABLE)
func _replicate_client_recieve(packet: Variant) -> void:
	_replicate_client(packet)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS)
func _replicate_client_recieve_unreliable(packet: Variant) -> void:
	_replicate_client(packet)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS_RELIABLE)
func _replicate_rpc(packet: Variant) -> void:
	_replicate_rpc_server(packet, multiplayer.get_remote_sender_id(), true)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS)
func _replicate_rpc_unreliable(packet: Variant) -> void:
	_replicate_rpc_server(packet, multiplayer.get_remote_sender_id(), false)

static func send(object: Object, properties: PackedStringArray, reliable: bool = true) -> void:
	if SimusNetConnection.is_server():
		var identity: SimusNetIdentity = SimusNetIdentity.register(object)
		if !identity.is_ready:
			await identity.on_ready
		
	else:
		_instance.logger.debug_error("only server can send variables. %s, %s" % [object, properties])

static func cache(property: String) -> void:
	if SimusNetConnection.is_server():
		if get_cached().has(property):
			return
		
		_instance._cache_rpc.rpc(property)

@rpc("authority", "call_local", "reliable", SimusNetChannels.BUILTIN.CACHE)
func _cache_rpc(property: String) -> void:
	get_cached().append(property)
	_event_cached.property = property
	_event_cached.publish()

static func uncache(property: String) -> void:
	if SimusNetConnection.is_server():
		if !get_cached().has(property):
			return
		
		_instance._uncache_rpc.rpc(property)

@rpc("authority", "call_local", "reliable", SimusNetChannels.BUILTIN.CACHE)
func _uncache_rpc(property: String) -> void:
	get_cached().erase(property)
	_event_uncached.property = property
	_event_uncached.publish()
