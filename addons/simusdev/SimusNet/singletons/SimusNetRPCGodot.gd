extends SimusNetSingletonChild
class_name SimusNetRPCGodot

static func register(callables: Array[Callable], 
rpc_mode: MultiplayerAPI.RPCMode = MultiplayerAPI.RPCMode.RPC_MODE_AUTHORITY,
transfer_mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE,
channel: Variant = 0) -> void:
	
	var config: Dictionary = {
		"rpc_mode" : rpc_mode,
		"transfer_mode" : transfer_mode,
		"call_local" : true,
		"channel" : SimusNetChannels.parse_and_get_id(channel)
	}
	
	for callable in callables:
		var object: Object = callable.get_object()
		if object is Node:
			object.rpc_config(callable.get_method(), config)

static func register_authority_reliable(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_AUTHORITY, MultiplayerPeer.TRANSFER_MODE_RELIABLE, channel)

static func register_any_peer_reliable(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_ANY_PEER, MultiplayerPeer.TRANSFER_MODE_RELIABLE, channel)

static func register_authority_unreliable(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_AUTHORITY, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, channel)

static func register_any_peer_unreliable(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_ANY_PEER, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, channel)

static func register_authority_unreliable_ordered(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_AUTHORITY, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, channel)

static func register_any_peer_unreliable_ordered(callables: Array[Callable], channel: Variant = 0) -> void:
	register(callables, MultiplayerAPI.RPC_MODE_ANY_PEER, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, channel)

static func invoke(callable: Callable, ...args: Array) -> void:
	_invoke(callable, args)

static func _invoke(callable: Callable, args: Array) -> void:
	for peer in SimusNetConnection.get_connected_peers():
		if SimusNetVisibility.is_visible_for(peer, callable.get_object()) and !SimusNetVisibility.is_method_always_visible(callable):
				_invoke_on(peer, callable, args)

static func invoke_all(callable: Callable, ...args: Array) -> void:
	_invoke_on(SimusNetConnection.get_unique_id(), callable, args)
	_invoke(callable, args)

static func _invoke_on(peer: int, callable: Callable, args: Array) -> void:
	if is_cooldown_active(callable):
		return
	
	var arr: Array = []
	arr.append(peer)
	arr.append(callable.get_method())
	arr.append_array(args)
	callable.get_object().callv("rpc_id", arr)
	SimusNetRPC._start_cooldown(callable)

static func invoke_on(peer: int, callable: Callable, ...args: Array) -> void:
	_invoke_on(peer, callable, args)

static func invoke_on_server(callable: Callable, ...args: Array) -> void:
	_invoke_on(SimusNetConnection.SERVER_ID, callable, args)

static func set_cooldown(callable: Callable, time: float = 0.0) -> SimusNetRPCGodot:
	SimusNetRPC.set_cooldown(callable, time)
	return singleton.RPCgodot

static func get_cooldown(callable: Callable) -> SD_CooldownTimer:
	return SimusNetRPC.get_cooldown(callable)

static func is_cooldown_active(callable: Callable) -> bool:
	return SimusNetRPC.is_cooldown_active(callable)
