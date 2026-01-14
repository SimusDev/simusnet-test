extends SimusNetSingletonChild
class_name SimusNetVars

const BUILTIN_CACHE: PackedStringArray = [
	"transform",
	"position",
	"rotation",
	"scale",
]

signal on_tick(delta: float)

@export var _processor_send: SimusNetVarsProccessorSend
static var _instance: SimusNetVars

static func get_instance() -> SimusNetVars:
	return _instance

static var _event_cached: SimusNetEventVariableCached
static var _event_uncached: SimusNetEventVariableUncached

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
	
	

static func register(object: Object, properties: PackedStringArray, config: SimusNetVarConfig = SimusNetVarConfig.new()) -> bool:
	config._initialize(object, properties)
	return true

func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

var _queue_replicate: Dictionary = {}
var _queue_replicate_unreliable: Dictionary = {}

var _queue_replicate_server: Dictionary = {}

var _queue_send: Dictionary = {}
var _queue_send_peers: PackedInt32Array = []

func _physics_process(delta: float) -> void:
	
	if !_queue_replicate.is_empty():
		_handle_replicate(_queue_replicate, true)
		_queue_replicate.clear()
	
	if !_queue_replicate_unreliable.is_empty():
		_handle_replicate(_queue_replicate_unreliable, false)
		_queue_replicate_unreliable.clear()
	
	if !_queue_replicate_server.is_empty():
		_handle_replicate_server(_queue_replicate_server)
		_queue_replicate_server.clear()
	
	if !_queue_send.is_empty():
		_handle_send(_queue_send, _queue_send_peers)
		_queue_send.clear()
		_queue_send_peers.clear()
	
	on_tick.emit(delta)
	

static func replicate(object: Object, properties: PackedStringArray, reliable: bool = true) -> void:
	for p_name in properties:
		var config: SimusNetVarConfig = SimusNetVarConfig.get_config(object, p_name)
		if !config:
			_instance.logger.debug_error("replicate(), cant find config for %s, property: %s" % [object, p_name])
			continue
		
		var validate: bool = await config._validate_replicate()
		if !validate:
			continue
		
		var identity: SimusNetIdentity = config.get_identity()
		var packet: Dictionary = _instance._queue_replicate_unreliable
		if reliable:
			packet = _instance._queue_replicate
		
		var data_properties: Array = packet.get_or_add(identity.try_serialize_into_variant(), [])
		
		var p_name_serialized: Variant = try_serialize_into_variant(p_name)
		if !data_properties.has(p_name_serialized):
			data_properties.append(p_name_serialized)
	

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
			logger.debug_error("_replicate_rpc_server() identity with %s ID was not found." % identity_id)
			continue
		
		var peer_data: Dictionary = _queue_replicate_server.get_or_add(peer, {})
		
		var properties: PackedStringArray = try_deserialize_array_from_variant(data[identity_id])
		
		var reliable_data: Dictionary = peer_data.get_or_add(reliable, {})
		var identity_data: Dictionary = reliable_data.get_or_add(identity_id, {})
		
		for p_name: String in properties:
			var config: SimusNetVarConfig = SimusNetVarConfig.get_config(identity.owner, p_name)
			if !config:
				continue
			
			var validated: bool = await config._validate_replicate_receive(peer)
			if !validated:
				continue
			
			if p_name in identity.owner:
				identity_data.set(try_serialize_into_variant(p_name), SimusNetSerializer.parse(identity.owner.get(p_name), config._serialize))
		
	
	

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
				var config: SimusNetVarConfig = SimusNetVarConfig.get_config(identity.owner, s_p)
				if !config:
					continue
				
				var value: Variant = SimusNetDeserializer.parse(data[identity_id][s_p], config._serialize)
				identity.owner.set(property, value)

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS_RELIABLE)
func _replicate_client_recieve(packet: Variant) -> void:
	if multiplayer.get_remote_sender_id() == SimusNet.SERVER_ID:
		_replicate_client(packet)

@rpc("authority", "call_remote", "unreliable", SimusNetChannels.BUILTIN.VARS)
func _replicate_client_recieve_unreliable(packet: Variant) -> void:
	if multiplayer.get_remote_sender_id() == SimusNet.SERVER_ID:
		_replicate_client(packet)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS_RELIABLE)
func _replicate_rpc(packet: Variant) -> void:
	if SimusNetConnection.is_server():
		_replicate_rpc_server(packet, multiplayer.get_remote_sender_id(), true)

@rpc("any_peer", "call_remote", "unreliable", SimusNetChannels.BUILTIN.VARS)
func _replicate_rpc_unreliable(packet: Variant) -> void:
	if SimusNetConnection.is_server():
		_replicate_rpc_server(packet, multiplayer.get_remote_sender_id(), false)

static func send(object: Object, properties: PackedStringArray, reliable: bool = true, log_error: bool = true) -> void:
	if SimusNet.is_network_authority(object) or SimusNetConnection.is_server():
		
		var changed_properties: Dictionary[StringName, Variant] = SimusNetSynchronization.get_changed_properties(object)
		for property in properties:
			
			if changed_properties.get_or_add(property, object.get(property)) == object.get(property):
				continue
			
			var config: SimusNetVarConfig = SimusNetVarConfig.get_config(object, property)
			if !config:
				_instance.logger.debug_error("send(), cant find config for %s, property: %s" % [object, property])
				continue
			
			var validate: bool = await config._validate_send()
			if !validate:
				continue
			
			if !config.is_ready:
				await config.on_ready
			
			var identity: SimusNetIdentity = config.get_identity()
			
			var channel: Dictionary = _instance._queue_send.get_or_add(config._channel, {})
			var transfer: Dictionary = channel.get_or_add(reliable, {})
			
			var identity_data: Dictionary = transfer.get_or_add(identity.try_serialize_into_variant(), {})
			
			identity_data.set(try_serialize_into_variant(property), SimusNetSerializer.parse(identity.owner.get(property), config._serialize))
			changed_properties.set(property, identity.owner.get(property))
			
			for p_id in SimusNetConnection.get_connected_peers():
				if SimusNetVisibility.is_visible_for(p_id, identity.owner):
					_instance._queue_send_peers.append(p_id)
				

	else:
		_instance.logger.debug_error("only network authority can send variables. %s, %s" % [object, properties])

func _handle_send(_queue: Dictionary, peers: PackedInt32Array) -> void:
	for peer: int in peers:
		for channel: int in _queue[peer]:
			for reliable: bool in _queue[peer][channel]:
				var identity_data: Dictionary = _queue[peer][channel][reliable]
				
				var callable: Callable
				
				if reliable:
					callable = _send_handle_callables.get(channel, Callable(_processor_send, "_r_s_p_l_r%s" % channel))
				else:
					callable = _send_handle_callables.get(channel, Callable(_processor_send, "_r_s_p_l_u%s" % channel))
				
				callable.rpc_id(peer, SimusNetCompressor.parse(identity_data))
				

@onready var _send_handle_callables: Dictionary[int, Callable] = {
	SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE: _processor_send._default_recieve_send,
	SimusNetChannels.BUILTIN.VARS_SEND: _processor_send._default_recieve_send_unreliable,
}


func _recieve_send_packet_local(packet: Variant, from_peer: int) -> void:
	var data: Dictionary = SimusNetDecompressor.parse(packet)
	
	
	for id in data:
		var identity: SimusNetIdentity = SimusNetIdentity.try_deserialize_from_variant(id)
		if !identity:
			logger.debug_error("recieve vars from peer(%s), identity with %s ID was not found." % [from_peer, id])
			continue
		
		if SimusNet.get_network_authority(identity.owner) == from_peer or (from_peer == SimusNet.SERVER_ID):
			for s_p in data[id]:
				var property: String = try_deserialize_from_variant(s_p)
				var config: SimusNetVarConfig = SimusNetVarConfig.get_config(identity.owner, property)
				if !config:
					continue
				
				var value: Variant = SimusNetDeserializer.parse(data[id][s_p], config._serialize)
				identity.owner.set(property, value)
				

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
