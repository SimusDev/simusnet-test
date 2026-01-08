extends SimusNetSingletonChild
class_name SimusNetConnection

const SERVER_ID: int = 1

static var _active: bool = false

static var _is_dedicated_server: bool = false

static var _instance: SimusNetConnection

var _is_was_server: bool = true

func initialize() -> void:
	_instance = self
	
	singleton.api.connection_failed.connect(_on_connection_failed)
	singleton.api.connected_to_server.connect(_on_connected_to_server)
	singleton.api.server_disconnected.connect(_on_server_disconnected)
	singleton.api.peer_connected.connect(_on_peer_connected_or_disconnected.bind(false))
	singleton.api.peer_disconnected.connect(_on_peer_connected_or_disconnected.bind(true))
	
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_peer_connected_or_disconnected(peer: int, disconnected: bool) -> void:
	if disconnected:
		SimusNetEvents.event_peer_disconnected.publish(peer)
	else:
		SimusNetEvents.event_peer_connected.publish(peer)

func _process(delta: float) -> void:
	if !get_peer():
		return
	
	if get_peer() is OfflineMultiplayerPeer:
		return
	
	if get_peer().get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		if !_active:
			_set_active(true, is_server())
			process_mode = Node.PROCESS_MODE_DISABLED
			
			_is_was_server = true
			
			if is_server():
				SimusNetEvents.event_connected.publish()
			
			


func _on_connected_to_server() -> void:
	_is_was_server = false
	_set_active(true, false)
	SimusNetHandShake._api_connected_to_server()

func _on_server_disconnected() -> void:
	_set_active(false, true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	SimusNetEvents.event_disconnected.publish()

func _on_connection_failed() -> void:
	pass

func _set_active(value: bool, server: bool) -> void:
	if _active == value:
		return
	
	_active = value
	singleton._set_active(value, server)
	SimusNetEvents.event_active_status_changed.publish()
	
	if not _active:
		SimusNetCache.clear()

static func is_active() -> bool:
	return _active

static func is_server() -> bool:
	if get_peer() and is_active():
		return singleton.api.is_server()
	return true

static func is_was_server() -> bool:
	return _instance._is_was_server

static func is_dedicated_server() -> bool:
	if is_server():
		return _is_dedicated_server
	return false

static func set_dedicated_server(value: bool) -> void:
	_is_dedicated_server = value

static func is_client() -> bool:
	return !is_dedicated_server()

static func get_peer() -> MultiplayerPeer:
	return singleton.api.multiplayer_peer

static func set_peer(peer: MultiplayerPeer) -> SimusNetConnection:
	singleton.api.multiplayer_peer = peer
	return singleton.connection

static func try_close_peer() -> SimusNetConnection:
	if get_peer():
		get_peer().close()
	return singleton.connection

static func get_connected_peers() -> PackedInt32Array:
	return singleton.api.get_peers()

static func get_connected_peers_include_self() -> PackedInt32Array:
	var peers: PackedInt32Array = get_connected_peers()
	if !is_dedicated_server():
		peers.append(get_unique_id())
	return peers

static func get_unique_id() -> int:
	if is_active():
		return singleton.api.get_unique_id()
	return SERVER_ID

static func connect_network_node_callables(object: Node, on_ready: Callable, on_disconnect: Callable, on_not_connected: Callable) -> void:
	if !is_active():
		on_not_connected.call()
		await SimusNetEvents.event_connected.published
	
	SimusNetEvents.event_connected.listen(on_ready)
	
	if !object.is_node_ready():
		await object.ready
	
	on_ready.call()
	
	SimusNetEvents.event_disconnected.listen(on_disconnect)
	
