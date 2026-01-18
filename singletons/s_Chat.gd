extends SimusNetChat

func _ready() -> void:
	super()
	
	SimusNetEvents.event_connected.listen(_on_connected)

func _on_connected() -> void:
	if SimusNetConnection.is_dedicated_server():
		$CanvasLayer.queue_free()
		SimusNetEvents.event_connected.unlisten(_on_connected)

func server_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message

func client_message_received(message: SimusNetChatMessage) -> SimusNetChatMessage:
	return message
