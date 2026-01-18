extends Node
class_name SimusNetChat

signal on_message_received(message: SimusNetChatMessage)

func _ready() -> void:
	SimusNetRPC.register(
		[
			_request_rpc
		], SimusNetRPCConfig.new().
		flag_set_channel("chat").flag_mode_any_peer()
	)
	
	SimusNetRPC.register(
		[
			_receive_msg
		], SimusNetRPCConfig.new().
		flag_set_channel("chat").flag_mode_server_only()
	)
	
	SimusNetConnection.connect_network_node_callables(self,
	_net_ready,
	_net_disconnect,
	_net_not_connected
	)
	
	
	

func request(message: SimusNetChatMessage) -> void:
	if message.get_text().is_empty():
		return
	
	SimusNetRPC.invoke_on_server(_request_rpc, message.serialize())

func _request_rpc(message: Variant) -> void:
	if SimusNetConnection.is_server():
		var deserialized: SimusNetChatMessage = SimusNetChatMessage.deserialize(message)
		deserialized._peer_id = SimusNetRemote.sender_id
		var parsed: SimusNetChatMessage = server_message_received(deserialized)
		SimusNetRPC.invoke_all(_receive_msg, parsed.serialize())
		

func _receive_msg(serialized: Variant) -> void:
	var deserialized: SimusNetChatMessage = SimusNetChatMessage.deserialize(serialized)
	var message: SimusNetChatMessage = client_message_received(deserialized)
	on_message_received.emit(message)

func server_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message

func client_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message

func _net_ready() -> void:
	pass

func _net_disconnect() -> void:
	pass

func _net_not_connected() -> void:
	pass
