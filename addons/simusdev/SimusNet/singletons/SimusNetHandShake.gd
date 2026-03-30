extends SimusNetSingletonChild
class_name SimusNetHandShake

static var _instance: SimusNetHandShake

var _handshake_data: Dictionary = {}

signal on_received(peer: int, data: Dictionary)

func initialize() -> void:
	_instance = self

static func _api_connected_to_server() -> void:
	_instance._on_connected_to_server()

static func get_handshake_data() -> Dictionary:
	return _instance._handshake_data

func _on_connected_to_server() -> void:
	_server_send.rpc_id(SimusNetConnection.SERVER_ID, SimusNetCompressor.parse_if_necessary(_handshake_data))

@rpc("any_peer", "call_local", "reliable", SimusNetChannels.BUILTIN.HANDSHAKE)
func _server_send(client_data_bytes: Variant) -> void:
	var data: Dictionary = {
		"cache" : SimusNetCache.get_data()
	}
	
	var client_data: Dictionary = SimusNetDecompressor.parse_if_necessary(client_data_bytes)
	on_received.emit(multiplayer.get_remote_sender_id(), client_data)
	
	_client_recieve.rpc_id(multiplayer.get_remote_sender_id(), SimusNetCompressor.parse_if_necessary(data), SimusNetCompressor.parse_if_necessary(_handshake_data))

@rpc("authority", "call_remote", "reliable", SimusNetChannels.BUILTIN.HANDSHAKE)
func _client_recieve(bytes: Variant, handshake_bytes: Variant) -> void:
	var handshake: Dictionary = SimusNetDecompressor.parse_if_necessary(handshake_bytes)
	
	var data: Dictionary = SimusNetDecompressor.parse_if_necessary(bytes)
	SimusNetCache._set_data(data.cache)
	
	on_received.emit(multiplayer.get_remote_sender_id(), handshake)
	
	SimusNetConnection._instance._is_connected = true
	SimusNetEvents.event_connected.publish()
