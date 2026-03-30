extends SimusNetSingletonChild
class_name SimusNetVars

signal on_tick(delta: float)

var _timer: Timer

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

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
	
	#for p in BUILTIN_CACHE:
		#cache(p)
	
	process_mode = Node.PROCESS_MODE_DISABLED
	
	singleton.api.peer_packet.connect(_on_peer_packet)
	
	#_timer = Timer.new()
	#_timer.wait_time = 1.0 / singleton.settings.synchronization_vars_tickrate
	#_timer.timeout.connect(_on_timer_tick)
	#add_child(_timer)
	

var PACKET_AND_METHOD: Dictionary[SimusNet.PACKET, Callable] = {
	SimusNet.PACKET.VARIABLES: _on_variable_received,
	SimusNet.PACKET.VARIABLE_REPLICATE: _on_variable_replicate_request,
}

func _on_peer_packet(id: int, packet: PackedByteArray) -> void:
	var deserialized: Array = SimusNet.deserialize_packet(packet)
	#var deserialized: Variant = bytes_to_var(packet)
	#print('received packet(%s, size: %s): %s' % [id, packet.size(), deserialized])
	var packet_id: SimusNet.PACKET = deserialized[0]
	var raw_data: PackedByteArray = deserialized[1]
	
	if packet_id in PACKET_AND_METHOD:
		var callable: Callable = PACKET_AND_METHOD[packet_id]
		callable.call(packet.size() + 1, packet_id, id, raw_data)
	

func _on_variable_received(og_packet_size: int, packet_type: SimusNet.PACKET, peer: int, raw_data: PackedByteArray) -> void:
	var arguments: Array = SimusNetArguments.deserialize(raw_data)
	var identity_id: int = arguments.pop_front()
	var property_id: int = arguments.pop_front()
	
	var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(identity_id)
	if !identity:
		logger.push_error("_on_variable_received() cant find identity with ID %s, %s, %s" % [identity_id, property_id])
		return
	
	if !identity.owner:
		logger.push_error("_on_variable_received() cant find identity owner with ID %s, %s, %s" % [identity_id, property_id])
		return
	
	var config_handler: SimusNetVarConfigHandler = SimusNetVarConfigHandler.find_in(identity.owner)
	if !config_handler:
		logger.push_error("_on_variable_received() cant find config handler on owner (%s) with ID %s, %s, %s" % [identity.owner, identity_id, property_id])
		return
	
	var property: StringName = config_handler.get_property_name_by_unique_id(property_id)
	if property.is_empty():
		logger.push_error("_on_variable_received() cant find property on owner (%s) with ID %s, %s, %s" % [identity.owner, identity_id, property_id])
		return
	
	var cfg: SimusNetVarConfig = config_handler._list.get(property)
	var value: Variant = SimusNetDeserializer.parse(arguments.pop_front(), cfg._serialize)
	
	if !cfg:
		logger.push_error("_on_variable_received() cant find config for property (%s) on owner (%s) with ID %s, %s, %s" % [property, identity.owner, identity_id, property_id, value])
		return
	
	if !cfg._validate_send_receive(config_handler, peer):
		return
	
	SimusNetProfiler._instance._put_var_traffic(og_packet_size, identity, property, true)
	
	identity.owner.set(property, value)
	config_handler.current_peer = peer
	config_handler.current_received_property = property
	config_handler.current_received_value = value
	config_handler.on_property_received.emit(property, peer)

static func register(object: Object, properties: PackedStringArray, config: SimusNetVarConfig = SimusNetVarConfig.new()) -> bool:
	var handler: SimusNetVarConfigHandler = SimusNetVarConfigHandler.get_or_create(object)
	for p in properties:
		handler._add_cfg(config, p)
	return true

func _on_connected() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
func _on_disconnected() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

var _queue_replicate: Dictionary = {}

var _queue_send_synced_types: Dictionary[SimusNetSyncedType, Array] = {}
var _queue_replicate_synced_types: Array[SimusNetSyncedType] = []
var _queue_replicate_send_synced_types: Dictionary = {}

func _physics_process(delta: float) -> void:
	if !_queue_replicate.is_empty():
		_handle_replicate(_queue_replicate)
		_queue_replicate.clear()
	
	if !_queue_send_synced_types.is_empty():
		_handle_send_synced_types(_queue_send_synced_types)
		_queue_send_synced_types.clear()
	
	if !_queue_replicate_synced_types.is_empty():
		_handle_replicate_synced_types(_queue_replicate_synced_types)
		_queue_replicate_synced_types.clear()
	
	if !_queue_replicate_send_synced_types.is_empty():
		_handle_send_replicate_synced_types(_queue_replicate_send_synced_types)
		_queue_replicate_send_synced_types.clear()
	
	on_tick.emit(delta)
	

static func _replicate(object: Object, property: String, async: bool) -> Variant:
	if SimusNetConnection.is_server():
		return object.get(property)
	
	if !is_instance_valid(object):
		return
	
	var handler: SimusNetVarConfigHandler = SimusNetVarConfigHandler.get_or_create(object)
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(object)
	if !is_instance_valid(identity):
		return
	
	if !identity.owner:
		return
	
	if !identity.is_ready:
		await identity.on_ready
	
	var config: SimusNetVarConfig = SimusNetVarConfig.get_config(object, property)
	if !config:
		_instance.logger.debug_error("replicate(), cant find config for %s, property: %s" % [object, property])
		return
	
	var validate: bool = await config._validate_replicate(handler)
	if !validate:
		return
	
	var variable_id: int = handler.get_property_unique_id(property)
	
	var packet: Dictionary = _instance._queue_replicate
	
	var channel_data: Dictionary = packet.get_or_add(config._channel, {})
	var data_properties: Array = channel_data.get_or_add(identity.get_unique_id(), [])
	if !data_properties.has(variable_id):
		data_properties.append(variable_id)
	
	if async:
		return await _instance._replicate_async_handler_await(weakref(handler), property)
	
	return null

func _replicate_async_handler_await(ref: WeakRef, property: String, from_peer: int = SimusNet.SERVER_ID) -> Variant:
	var handler: SimusNetVarConfigHandler = ref.get_ref()
	if !handler:
		return null
	
	if handler.current_peer == from_peer:
		if handler.current_received_property == property:
			return handler.current_received_value
	
	await handler.on_property_received
	return await _replicate_async_handler_await(ref, property, from_peer)

static func replicate(object: Object, property: String) -> void:
	_replicate(object, property, false)

static func replicate_async(object: Object, property: String) -> Variant:
	return await _replicate(object, property, true)

func _handle_replicate(data: Dictionary) -> void:
	for channel: int in data:
		var channel_data: Dictionary = data[channel]
		var bytes: PackedByteArray = SimusNet.serialize_packet(
			SimusNet.PACKET.VARIABLE_REPLICATE,
			SimusNetDictionarySerializer.serialize(channel_data),
			)
		
		singleton.api.send_bytes(bytes, SimusNet.SERVER_ID, MultiplayerPeer.TRANSFER_MODE_RELIABLE, channel)
		SimusNetProfiler._put_up_packet()
		SimusNetProfiler._instance._put_up_traffic(bytes.size() + 1)


func _on_variable_replicate_request(og_packet_size: int, packet_type: SimusNet.PACKET, peer: int, raw_data: PackedByteArray) -> void:
	if !SimusNetConnection.is_server():
		return
	
	var data: Dictionary = SimusNetDictionarySerializer.deserialize(raw_data)
	
	for identity_id: int in data:
		var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(identity_id)
		if !identity:
			logger.push_error("_on_variable_replicate_request() (from peer: %s), cant find identity with ID %s, data: (%s)" % [peer, identity_id, data])
			continue
		
		if !identity.owner:
			logger.push_error("_on_variable_replicate_request() (from peer: %s), cant find identity with ID %s, data: (%s)" % [peer, identity_id, data])
			continue
		
		SimusNetVisibility.set_visible_for(peer, identity.owner, true)
		
		var properties: Array = data[identity_id]
		var handler: SimusNetVarConfigHandler = SimusNetVarConfigHandler.find_in(identity.owner)
		if !handler:
			logger.push_error("_on_variable_replicate_request() (from peer: %s), cant find VarConfigHandler for %s, data: (%s)" % [peer, identity.owner, data])
			continue
		
		var validated_properties: PackedStringArray = []
		
		for property_id: int in properties:
			var property: StringName = handler.get_property_name_by_unique_id(property_id)
			if property.is_empty():
				logger.push_error("_on_variable_replicate_request() (from peer: %s), cant find method name by ID %s, for %s, data: (%s)" % [peer, property_id, identity.owner, data])
				continue
			
			var config: SimusNetVarConfig = SimusNetVarConfig.get_config(identity.owner, property)
			if config._validate_replicate_receive(handler, peer):
				send(identity.owner, property, [peer])

static func _hook_snapshot(data: Dictionary[StringName, Variant], property: String, object: Object) -> bool:
	var value: Variant = object.get(property)
	if value is Array or value is Dictionary:
		return value.size() == data.get_or_add(property, value.size())
	return data.get_or_add(property, value) == object.get(property)

static func send(object: Object, property: String, target_peers: PackedInt32Array = [], log_error: bool = true) -> void:
	var handler: SimusNetVarConfigHandler = SimusNetVarConfigHandler.get_or_create(object)
	var config: SimusNetVarConfig = SimusNetVarConfig.get_config(object, property)
	if !config:
		_instance.logger.debug_error("send(), cant find config for %s, property: %s" % [object, property])
		return
	
	SimusNetSerializer._current_blocked_methods = config._serializer_blocked_methods
	
	var identity: SimusNetIdentity = handler.get_identity()
	
	if !identity.is_ready:
		await identity.on_ready
	
	var p: int = handler.get_property_unique_id(property)
	var v: Variant = SimusNetSerializer.parse(identity.owner.get(property), config._serialize)
	
	var raw_packet: Array = [
		identity.get_unique_id(),
		p,
		v
	]
	
	var packet_bytes: PackedByteArray = SimusNet.serialize_packet(
		SimusNet.PACKET.VARIABLES,
		SimusNetArguments.serialize(raw_packet)
		)
	
	var peers: PackedInt32Array = target_peers
	if target_peers.is_empty():
		peers = SimusNetConnection.get_connected_peers()
	
	for p_id in peers:
		if SimusNetVisibility.is_visible_for(p_id, identity.owner):
			var validate: bool = await config._validate_send(handler, p_id)
			if !validate:
				continue
			
			if config._reliable:
				singleton.api.send_bytes(packet_bytes, p_id, MultiplayerPeer.TRANSFER_MODE_RELIABLE, config._channel)
			else:
				singleton.api.send_bytes(packet_bytes, p_id, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, config._channel)
			
			SimusNetProfiler._put_up_packet()
			SimusNetProfiler._instance._put_up_traffic(packet_bytes.size() + 1)
			SimusNetProfiler._instance._put_var_traffic(packet_bytes.size(), identity, property, false)

@onready var _send_handle_callables: Dictionary[int, Callable] = {
	SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE: _processor_send._default_recieve_send,
	SimusNetChannels.BUILTIN.VARS_SEND: _processor_send._default_recieve_send_unreliable,
}

func _replicate_synced_type(type: SimusNetSyncedType) -> void:
	if SimusNetConnection.is_server():
		return
	
	if !type.is_ready:
		await type.on_ready
	
	_queue_replicate_synced_types.append(type)
	

func _handle_replicate_synced_types(data: Array[SimusNetSyncedType]) -> void:
	var packet: Dictionary = {}
	for i in data:
		if i.get_owner():
			packet.set(i.identity.get_unique_id(), i.network_id)
	
	if packet.is_empty():
		return
	
	var bytes: Variant = var_to_bytes(packet)
	var size: int = bytes.size()
	bytes = bytes.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
	_server_receive_synced_types_from_client.rpc_id(SimusNet.SERVER_ID, bytes, size)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.SYNCED_TYPES)
func _server_receive_synced_types_from_client(bytes: Variant, uncompressed_size: int) -> void:
	bytes = bytes.decompress(uncompressed_size, FileAccess.CompressionMode.COMPRESSION_ZSTD)
	var packet: Dictionary = bytes_to_var(bytes)
	
	for id in packet:
		var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(id)
		if !identity:
			continue
		
		if !identity.owner:
			continue
		
		SimusNetVisibility.set_visible_for(multiplayer.get_remote_sender_id(), identity.owner, true)
		
		var handler: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.get_or_create(identity.owner)
		var synced_type: SimusNetSyncedType = handler.get_synced_type_by_id(packet[id])
		if !synced_type:
			continue
		
		var to_peer_data: Dictionary = _queue_replicate_send_synced_types.get_or_add(multiplayer.get_remote_sender_id(), {})
		var identity_data: Dictionary = to_peer_data.get_or_add(identity.get_unique_id(), {})
		identity_data.set(synced_type.network_id, synced_type._start_replicate_serialize())
	

func _handle_send_replicate_synced_types(data: Dictionary) -> void:
	if !SimusNetConnection.is_server():
		return
	
	for p_id: int in data:
		var peer_data: Dictionary = data[p_id]
		var bytes: Variant = var_to_bytes(peer_data)
		var size: int = bytes.size()
		bytes = bytes.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
		_receive_replication_from_server.rpc_id(p_id, bytes, size)
		

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.SYNCED_TYPES)
func _receive_replication_from_server(bytes: Variant, uncompressed_size: int) -> void:
	bytes = bytes.decompress(uncompressed_size, FileAccess.CompressionMode.COMPRESSION_ZSTD)
	var data: Dictionary = bytes_to_var(bytes)
	
	for identity_id: int in data:
		var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(identity_id)
		if !identity:
			continue
		
		if !identity.owner:
			continue
		
		var handler: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.get_or_create(identity.owner)
		
		for sync_id: int in data[identity_id]:
			var synced_type: SimusNetSyncedType = handler.get_synced_type_by_id(sync_id)
			if !synced_type:
				continue
			
			var serialized: Variant = data[identity_id][sync_id]
			synced_type._on_replication_received(synced_type._start_replicate_deserialize(serialized))

func _update_send_synced_type(type: SimusNetSyncedType) -> void:
	if !type.is_ready:
		await type.on_ready
	
	var changes: Array = _queue_send_synced_types.get_or_add(type, [])
	changes.append_array(type.___changes)

func _handle_send_synced_types(data: Dictionary[SimusNetSyncedType, Array]) -> void:
	var packet: Dictionary = {}
	
	for i in data:
		if i.get_owner():
			var changes: Array = data[i]
			var visible: SimusNetVisible = SimusNetVisible.get_or_create(i.get_owner())
			
			for peer_id in SimusNetConnection.get_connected_peers():
				if !visible.is_visible_for(peer_id):
					continue
				
				if i._validate_send(peer_id):
					var peer_data: Dictionary = packet.get_or_add(peer_id, {})
					var identity_data: Dictionary = peer_data.get_or_add(i.identity.get_unique_id(), {})
					identity_data.set(i.network_id, changes)
	
	if packet.is_empty():
		return
	
	for p_id: int in packet:
		var bytes: Variant = var_to_bytes(packet[p_id])
		var size: int = bytes.size()
		bytes = bytes.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
		_receive_sent_synced_types.rpc_id(p_id, bytes, size)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.SYNCED_TYPES)
func _receive_sent_synced_types(bytes: Variant, uncompressed_size: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	bytes = bytes.decompress(uncompressed_size, FileAccess.CompressionMode.COMPRESSION_ZSTD)
	
	var data: Dictionary = bytes_to_var(bytes)
	
	for id: int in data:
		var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(id)
		if !identity:
			continue
		
		if !identity.owner:
			continue
		
		var handler: SimusNetSyncedTypeHandler = SimusNetSyncedTypeHandler.get_or_create(identity.owner)
		
		for sync_id: int in data[id]:
			var synced_type: SimusNetSyncedType = handler.get_synced_type_by_id(sync_id)
			if !synced_type:
				continue
			
			if !synced_type._validate_receive(sender):
				continue
			
			var changes: Array = data[id][sync_id]
			synced_type._on_changes_received(changes)
		
	

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
