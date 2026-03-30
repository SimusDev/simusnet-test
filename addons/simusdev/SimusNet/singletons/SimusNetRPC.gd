extends SimusNetSingletonChild
class_name SimusNetRPC

enum TRANSFER_MODE {
	RELIABLE = MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE,
	UNRELIABLE = MultiplayerPeer.TransferMode.TRANSFER_MODE_UNRELIABLE,
	UNRELIABLE_ORDERED = MultiplayerPeer.TransferMode.TRANSFER_MODE_UNRELIABLE_ORDERED,
}

static var _instance: SimusNetRPC

@export var _processor: SimusNetRPCProccessor

const RPC_BYTE_SIZE: int = 2

static var CONFIG: SimusNetRPCConfig = SimusNetRPCConfig.new().flag_mode_authority()
static var CONFIG_TO_SERVER: SimusNetRPCConfig = SimusNetRPCConfig.new().flag_mode_to_server()
static var CONFIG_SERVER_ONLY: SimusNetRPCConfig = SimusNetRPCConfig.new().flag_mode_server_only()
static var CONFIG_ANY_PEER: SimusNetRPCConfig = SimusNetRPCConfig.new().flag_mode_any_peer()

static var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

static func register(callables: Array[Callable], config: SimusNetRPCConfig = CONFIG) -> bool:
	for function in callables:
		SimusNetIdentity.register(function.get_object())
		SimusNetRPCConfig._append_to(function, config)
	
	return true

func initialize() -> void:
	_instance = self
	singleton.api.peer_packet.connect(_on_peer_packet_received)

func _validate_callable(callable: Callable, on_recieve: bool = false, peer: int = -1) -> SimusNetRPCConfig:
	var object: Object = callable.get_object()
	var config: SimusNetRPCConfig = SimusNetRPCConfig.try_find_in(callable)
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(object)
	if !config:
		logger.push_error("cant invoke rpc (%s), failed to find rpc config for %s" % [callable, object])
		return null
	
	var rpc_valide: bool = false
	
	if on_recieve:
		rpc_valide = await config._validate_on_recieve(handler, callable, peer)
	else:
		rpc_valide = await config._validate(handler, callable, peer)
	
	if rpc_valide:
		return config
	
	#logger.push_error("failed to validate callable %s" % callable)
	return null

static func invoke(callable: Callable, ...args: Array) -> void:
	_instance._invoke(callable, args)

static func invoke_all(callable: Callable, ...args: Array) -> void:
	_instance._invoke(callable, args)
	_instance._invoke_on(SimusNetConnection.get_unique_id(), callable, args)

func _invoke(callable: Callable, args: Array) -> void:
	if !SimusNetConnection.is_active():
		return
	
	var config: SimusNetRPCConfig = await _validate_callable(callable)
	if !config:
		return
	
	var object: Object = callable.get_object()
	
	var visibility: SimusNetVisible = SimusNetVisible.get_or_create(object)
	
	for id in SimusNetConnection.get_connected_peers():
		if visibility.is_method_always_visible(callable):
			_invoke_on_without_validating(id, callable, args, config)
		else:
			_try_invoke_by_visibility(id, visibility, callable, args, config)

func _try_invoke_by_visibility(peer: int, visible: SimusNetVisible, callable: Callable, args: Array, config: SimusNetRPCConfig, async: bool = false) -> void:
	if visible.is_visible_for(peer):
		_invoke_on_without_validating(peer, callable, args, config)
		return

func _invoke_on_without_validating(peer: int, callable: Callable, args: Array, config: SimusNetRPCConfig, async: bool = false) -> void:
	if !SimusNetConnection.is_active():
		return
	
	var object: Object = callable.get_object()
	var config_handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(object)
	
	if is_cooldown_active(callable) or !is_instance_valid(object):
		return
	
	var identity: SimusNetIdentity = SimusNetIdentity.try_find_in(object)
	if !identity.is_ready:
		await identity.on_ready
	
	SimusNetSerializer._current_blocked_methods = config._serializer_blocked_methods
	
	var unique_id: int = identity.get_unique_id()
	
	var packet: Array = [
		unique_id,
		config_handler.get_method_unique_id(callable.get_method())
		]
	
	for i in args:
		packet.append(SimusNetSerializer.parse(i))
	
	#print("sender(%s): %s" % [peer, packet])
	
	#if object is C_Inventory:
		#pass
	#
	var bytes: PackedByteArray = SimusNet.serialize_packet(
		SimusNet.PACKET.RPC,
		SimusNetArguments.serialize(packet),
	)
	
	#var bytes: PackedByteArray = var_to_bytes(packet)
	#if object is C_Inventory:
		#print("SimusNet:", bytes.size())
		#print("Godot:", var_to_bytes(bytes).size())
	
	singleton.api.send_bytes(bytes, 
	peer, config.flag_get_transfer_mode_multiplayer_peer(), 
	config.flag_get_channel_id())
	
	SimusNetProfiler.get_instance()._put_up_traffic(bytes.size() + 1)
	SimusNetProfiler.get_instance()._put_rpc_traffic(
		bytes.size() + 1,
		identity,
		callable,
		false
	)
	
	SimusNetProfiler.get_instance()._put_up_packet()
	_start_cooldown(callable)
	

var PACKET_AND_METHOD: Dictionary[SimusNet.PACKET, Callable] = {
	SimusNet.PACKET.RPC: _on_packet_rpc,
	SimusNet.PACKET.RPC_DEFLATE: _on_packet_rpc,
	SimusNet.PACKET.RPC_ZSTD: _on_packet_rpc,
	SimusNet.PACKET.RPC_ASYNC: _on_packet_rpc,
	SimusNet.PACKET.RPC_ASYNC_DELFATE: _on_packet_rpc,
	SimusNet.PACKET.RPC_ASYNC_ZSTD: _on_packet_rpc,
}

func _on_peer_packet_received(id: int, packet: PackedByteArray) -> void:
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler.get_instance()._put_down_traffic(packet.size() + 1)
	
	var deserialized: Array = SimusNet.deserialize_packet(packet)
	#var deserialized: Variant = bytes_to_var(packet)
	#print('received packet(%s, size: %s): %s' % [id, packet.size(), deserialized])
	var packet_id: SimusNet.PACKET = deserialized[0]
	var raw_data: PackedByteArray = deserialized[1]
	deserialized.pop_front()
	
	if packet_id in PACKET_AND_METHOD:
		var callable: Callable = PACKET_AND_METHOD[packet_id]
		callable.call(packet.size() + 1, packet_id, id, SimusNetArguments.deserialize(raw_data))
	

func _on_packet_rpc(original_packet_size: int, type: SimusNet.PACKET, peer: int, args: Array) -> void:
	var metadata: Dictionary = {}
	var i: int = args[0]
	var m: int = args[1]
	for c in 2:
		args.pop_front()
	_receive_rpc(original_packet_size, peer, i, m, args)

func _receive_rpc(original_packet_size: int, peer: int, identity_id: int, method_id: int, args: Array, metadata: Dictionary = {}) -> void:
	SimusNetRemote.sender_id = peer
	#print('received rpc: %s, %s, %s, %s' % [peer, identity_id, method_id, args])
	var identity: SimusNetIdentity = SimusNetIdentity.get_dictionary_by_unique_id().get(identity_id)
	if !identity:
		logger.push_error("identity with %s ID was not found on your instance" % identity_id)
		return
	
	if !identity.owner:
		logger.push_error("identity owner with %s ID was not found on your instance" % identity_id)
		return
	
	var object: Object = identity.owner
	SimusNetVisibility.set_visible_for(peer, object, true)
	
	var rpc_handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(object)
	var method_name: StringName = rpc_handler.get_method_name_by_unique_id(method_id)
	if method_name.is_empty():
		logger.push_error("cant find method name by unique id: %s: %s" % [object, method_id])
		return
	
	var callable: Variant = rpc_handler.get_callable_by_method_name(method_name)
	if callable == null:
		logger.push_error("cant find callable by method name: %s: %s" % [object, method_name])
		return
	
	SimusNetProfiler.get_instance()._put_rpc_traffic(
	original_packet_size,
	identity,
	callable,
	true
	)
	
	var validated_config: SimusNetRPCConfig = await _validate_callable(callable, true)
	if !validated_config and peer != SimusNet.SERVER_ID:
		return
	
	var parsed_args: Array = []
	
	for i in args:
		parsed_args.append(SimusNetDeserializer.parse(i, validated_config._serialization))
	#print(peer, ": ", parsed_args)
	#print('received rpc: %s, %s, %s' % [identity.owner, callable, parsed_args])
	#print(parsed_args)
	callable.callv(parsed_args)

static func invoke_on(peer: int, callable: Callable, ...args: Array) -> void:
	_instance._invoke_on(peer, callable, args)

static func invoke_on_server(callable: Callable, ...args: Array) -> void:
	_instance._invoke_on(SimusNetConnection.SERVER_ID, callable, args)

static func invoke_on_sender(callable: Callable, ...args: Array) -> void:
	_instance._invoke_on(SimusNetRemote.sender_id, callable, args)

#static func async_invoke_on(peer: int, callable: Callable, ...args: Array) -> Variant:
	#return await _instance._async_invoke_on(peer, callable, args)
#
#static func async_invoke_on_server(callable: Callable, ...args: Array) -> Variant:
	#return await _instance._async_invoke_on(SimusNetConnection.SERVER_ID, callable, args)
#
#static func async_invoke_on_sender(callable: Callable, ...args: Array) -> Variant:
	#return await _instance._async_invoke_on(SimusNetRemote.sender_id, callable, args)
#
#func _async_invoke_on(peer: int, callable: Callable, args: Array) -> Variant:
	#return await _invoke_on(peer, callable, args, true)

func _invoke_on(peer: int, callable: Callable, args: Array, async: bool = false) -> Variant:
	var handler: SimusNetRPCConfigHandler = SimusNetRPCConfigHandler.get_or_create(callable.get_object())
	var config: SimusNetRPCConfig = await _validate_callable(callable, false, peer)
	if !config:
		return
	
	if SimusNetConnection.get_unique_id() == peer:
		if is_cooldown_active(callable):
			return
		
		var serialized_args: Array = []
		var bytes: PackedByteArray = []
		SimusNetSerializer._current_blocked_methods = config._serializer_blocked_methods
		
		if config._simulate and config._serialization:
			for i in args:
				serialized_args.append(SimusNetSerializer.parse(i))
				
			bytes = SimusNetArguments.serialize(serialized_args)
		
		SimusNetRemote.sender_id = peer
		_start_cooldown(callable)
		
		if bytes.is_empty():
			return callable.callv(args)
		else:
			var deserialized: Array = SimusNetArguments.deserialize(bytes)
			var d_args: Array = []
			for i in deserialized:
				d_args.append(SimusNetDeserializer.parse(i))
			
			return callable.callv(d_args)
		
		return null
	
	if async:
		return await _await_async_and_get_variant(handler, config, callable)
	
	_invoke_on_without_validating(peer, callable, args, config, async)
	return null

func _await_async_and_get_variant(handler: SimusNetRPCConfigHandler, config: SimusNetRPCConfig, callable: Callable) -> Variant:
	if !is_instance_valid(handler) or !handler.get_object():
		return null
	
	await handler._async_received
	
	if callable.is_valid() and !callable.is_null():
		if handler._async_method == callable.get_method():
			return handler._async_args
	return await _await_async_and_get_variant(handler, config, callable)

const _META_COOLDOWN: String = "netrpcs_cooldown"

static func _cooldown_create_or_get_storage(callable: Callable) -> Dictionary[String, SimusNetCooldownTimer]:
	var object: Object = callable.get_object()
	var storage: Dictionary[String, SimusNetCooldownTimer] = {}
	
	if is_instance_valid(object):
		if object.has_meta(_META_COOLDOWN):
			storage = object.get_meta(_META_COOLDOWN)
		else:
			object.set_meta(_META_COOLDOWN, storage)
	return storage

static func set_cooldown(callable: Callable, time: float = 0.0) -> SimusNetRPC:
	var timer := SimusNetCooldownTimer.new()
	_cooldown_create_or_get_storage(callable)[callable.get_method()] = timer
	timer.set_time(time)
	return _instance

static func get_cooldown(callable: Callable) -> SimusNetCooldownTimer:
	var storage: Dictionary[String, SimusNetCooldownTimer] = _cooldown_create_or_get_storage(callable)
	return storage.get(callable.get_method())

static func is_cooldown_active(callable: Callable) -> bool:
	var timer: SimusNetCooldownTimer = get_cooldown(callable)
	if timer:
		return timer.is_active()
	return false

static func _start_cooldown(callable: Callable) -> SimusNetRPC:
	var timer: SimusNetCooldownTimer = get_cooldown(callable)
	if timer:
		timer.start()
	return _instance
